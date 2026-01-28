# frozen_string_literal: true

class OrdersController
  def index
    orders = Order.page(params[:page]).per(50)

    respond_to do |format|
      format.html do
        render :index, locals: {
          orders: orders
        }
      end
    end
  end
end
