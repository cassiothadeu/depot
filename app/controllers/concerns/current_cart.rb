module CurrentCart
  extend ActiveSupport::Concern

  private

    def set_cart 
      @cart = Cart.find(session[:cart_id])
    rescue ActiveRecord::RecordNotFound
      @cart = Cart.create
      session[:cart_id] = @cart.id
    end

    def set_count
    	@count = session[:counter]
    	if @count.nil?
    		@count = 0
    	else
    		@count += 1
    	end
    	session[:counter] = @count
    end
end