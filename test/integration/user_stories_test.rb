require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products

  #A user goes to the index page. They select a product, adding it to their
  #cart, and check out, filling in their details on the checkout form. When
  #they submit, an order is created containing their information, along with a
  #single line item corresponding to the product they added to their cart.

  test "buying a product" do
    #clear the structure
    LineItem.delete_all
    Order.delete_all
    ruby_book = products(:ruby)

    #go to index and verify the return
    get "/"
    assert_response :success
    assert_template "index"

    #send the request to select a item via ajax, and verify the request
    xml_http_request :post, '/line_items', product_id: ruby_book.id
    assert_response :success

    #verify the product in the cart
    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product

    #Redirect to check out
    get "/orders/new"
    assert_response :success
    assert_template "new"

    #send the post with the fields of form
    #verify success and redirect
    #verify empty cart after order
    post_via_redirect "/orders",
                      order: { name:     "Dave Thomas",
                               address:  "123 The Street",
                               email:    "dave@example.com",
                               pay_type: "Check" }
    assert_response :success
    assert_template "index"
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size

    #verify orders in database, with data of form
    #and product purchased
    orders = Order.all
    assert_equal 1, orders.size
    order = orders[0]

    assert_equal "Dave Thomas",      order.name
    assert_equal "123 The Street",   order.address
    assert_equal "dave@example.com", order.email
    assert_equal "Check",            order.pay_type

    assert_equal 1, order.line_items.size
    line_item = order.line_items[0]
    assert_equal ruby_book, line_item.product

    #verify if emails was delivered with address and subject
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["dave@example.com"], mail.to
    assert_equal 'Sam Ruby <depot@example.com>', mail[:from].value
    assert_equal "Pragmatic Store Order Confirmation", mail.subject

  end
end
