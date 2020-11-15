class Api::V2::ChatsController < Api::V2::ApiController
  require 'ostruct'
   before_action :require_login
   before_action :set_chat, only: [:show]
   before_action :check_admin, only: [:index, :show]
   
   #GET /chats
   def index
     @chats = Chat.all

     render json: @chats
     #Fazer paginação nessa rota
   end
  
   #GET /chats/sender/:id
   def get_by_sender
     @chats = Chat.where(sender_id: params[:sender_id])
     if (session_user.id != params[:sender_id].to_i && session_user.user_type != "admin")
      render json: {"error": "Error: Current user is not the sender or admin."}
      return 400
    end

     render json: @chats
     #Fazer paginação nessa rota
   end
  
   #GET /chats/receiver/:id
   def get_by_receiver
     @chats = Chat.where(receiver_id: params[:receiver_id])

     if (session_user.id != params[:receiver_id].to_i && session_user.user_type != "admin")
      render json: {"error": "Error: Current user is not the sender or admin."}
      return 400
    end

     render json: @chats
     #Fazer paginação nessa rota
   end


   #GET /chats/order/?page=pagina&id=id
   def get_by_order
    page = params[:page].to_i

    if page == 0
      page = 1
    elsif page < 0
      render json: {"error": "Error: page is lesser then 1."}
      return 400
    end

    order = Order.find(params[:order_id].to_i)
    @chats = Chat.where(order_id: params[:order_id]).page(page)
    total_pages = @chats.total_pages

    if page > total_pages
      render json: {"error": "Error: page is greater then total_pages."}
      return 400
    end

    chat_sample = @chats[0]
    if ((session_user.id != chat_sample.sender_id && session_user.id != chat_sample.receiver_id) && session_user.user_type != "admin")
      render json: {"error": "Current user doesn't have permission to acess this."}
      return 400
    end
    
    if (session_user.user_type != "admin" && (order.order_status == "finalizado" || order.order_status == "cancelado" || order.order_status == "analise"))
      response = {"chats": [], "current_page": 1, "total_pages": 1}
    else
      response = {"chats": @chats, "current_page": @chats.current_page, "total_pages": total_pages}
    end

    render json: response
    return 200
  end
  

  #GET /chats/list/?page=pagina
  def get_chat_list
    page = params[:page].to_i
    i = 0
    list = []

    if page == 0
      page = 1

    elsif page < 1
      render json: {"error": "Error: page is lesser then 1."}
      return 400

    end
    #list = select order_id, profile_photo as receiver_prophile_photo, service_type, receiver_name, title as service_type + receiver_name, message, created_at
    #from chats inner join orders on (orders.id = chats.order_id) inner join users on (user.id = chats.sender_id) inner join photo on (user.id = photo.id) ver

    orders = Order.where("user_id = ? OR professional = ?", session_user.id, session_user.id)#.where.not(order_status: :finalizado).where.not(order_status: :cancelado).where.not(order_status: :analise)
    
    if orders == nil
      render json: {"error": "Error: Current user doesn't have any valid active orders."}
      return 400
    end

    #Total de pedidos validos associados a alguma mensagem
    total = orders.length

      while(i < 10)
        order = orders[ (page * 10) + i - 10]
        
        #Loop chegou ao fim, pois os pedidos validos acabaram
        if order == nil
          break
        end

        order_id = order.id
        
        #Encontra a ultima entrada em chats aonde o campo order_id é igual a variável order_id
        last_chat = Chat.where(order_id: order_id).last
        
        #Caso o determinado pedido ainda não tenha mensagens associadas a ele
        if last_chat == nil

          if session_user.user_type == "user"
            receiver_id = order.professional_order.id
          elsif session_user.user_type == "professional"
            receiver_id = order.user.id
          end

          last_chat = OpenStruct.new({"message": nil, "created_at": nil, "receiver_id": receiver_id})
        end

        receiver_profile_photo = User.find(last_chat.receiver_id).user_profile_photo

        service_type = order.category.name + " - "
        receiver_name = User.find(last_chat.receiver_id).name

        title = service_type + receiver_name
      
        last_message = {"message": last_chat.message, "created_at": last_chat.created_at}

        list << {"order_id": order_id,
        "receiver_profile_photo": receiver_profile_photo,
        "title": title,
        "last_message": last_message
        }
        i += 1
      end

    render json: {"list": list, "page": page, "total": total}
    return 200
  end

  #GET /chats/:id
  def show
    render json: @chat
  end
  
  #POST /chats
  def create
    @chat = Chat.new(chat_params)
    
    #Criar exceção para caso as tres linhas abaixo retornem um erro 404, mostrar mensagem de erro especifica.

    @sender = User.find(chat_params[:sender_id]) #ver find one
    @receiver = User.find(chat_params[:receiver_id]) #ver find one
    @order = Order.find(chat_params[:order_id]) #ver find one
    

    if (session_user != User.find(@chat.sender_id))
      render json: {"error": "Error: Current user is not the sender."}
      return 400
    end

    if (@sender == @receiver)
      render json: {"error": "Error: Sender can not be the receiver."}
      return 401
    end
    
    if @chat.save
      render json: @chat, status: :created
    else

      #Ver como ele pode cair aqui
      render json: @chat.errors, status: :unprocessable_entity
    end
    
  end
  
  # PATCH/PUT /chats/:id
  #def update
  # Only sender can update chat, not even admin.
  #  if (session_user != User.find(params[:sender_id]))
  #    render json: {"error": "Error: Current user is not the sender."}
  #    return 400
  #  end

  #  if @chat.update(chat_params)
  #    render json: @chat
  #  else
  #    render json: @chat.errors, status: :unprocessable_entity
  #  end
  
  #end
  
  # DELETE /chats/:id
  #def destroy
  #   Only sender can delete chat, not even admin.
  #  if (session_user != User.find(@chat.sender_id))
  #    render json: {"error": "Error: Current user is not the sender."}
  #    return 400
  #  end

  #  @chat.destroy
  #end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chat
      @chat = Chat.find(params[:id])
    end

    def chat_params
      params.require(:chat).permit(:message, :is_read, :sender_id, :receiver_id, :created_at, :updated_at, :order_id)
    end

    def check_user_receiver
      #Not in use, but coded, in case its needed.
      if (session_user != User.find(@chat.receiver_id) && session_user.user_type != "admin")
        render json: {"error": "Error: Current user is not the receiver."}
        return 400
      end

      return 200
    end

    def check_user_sender
      if (session_user != User.find(@chat.sender_id) && session_user.user_type != "admin")
        render json: {"error": "Error: Current user is not the sender."}
        return 400
      end

      return 200
    end

    def check_admin
      if (session_user.user_type == "admin")
        return 200
      end

      render json: {"error": "Error: Admin privileges required."}
      return 400
    end
  
end
