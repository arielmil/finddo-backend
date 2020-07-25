class Api::V2::AddressesController < Api::V2::ApiController
  before_action :require_login
  before_action :set_address, only: [:show, :update, :destroy]

  # GET /addresses
  def index
    @addresses = Address.all

    render json: @addresses
  end

  def get_by_user
    @addresses = Address.where(user_id: params[:user_id])

    render json: @addresses
  end

  # GET /addresses/1
  def show
    render json: @address
  end

  # POST /addresses
  def create
    @address = Address.new(address_params)

    if @address.save
      render json: @address, status: :created
    else
      render json: @address.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /addresses/1
  def update
    if @address.update(address_params)
      render json: @address
    else
      render json: @address.errors, status: :unprocessable_entity
    end
  end

  # DELETE /addresses/1
  def destroy
    @address.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_address
      @address = Address.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def address_params
      params.require(:address).permit(:name, :street, :number, :complement, :cep, :district, :user_id, :selected)
    end
end