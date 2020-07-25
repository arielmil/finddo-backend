class ServicesModule::V2::UserService < ServicesModule::V2::BaseService

  def initialize
    @payment_gateway_service = ServicesModule::V2::PaymentGatewayService.new
  end

  def find_user(id)
    User.find_by(id: id)
  end

  def valid_user(params)
    if params[:email].nil? && params[:cellphone].nil? && params[:cpf].nil?
      raise ServicesModule::V2::ExceptionsModule::NoParamsException.new
    end

    user = User.find_by(email: params[:email])
    if user
      { error: 'Já existe um usuário com esse email.' }
    else
      user = User.find_by(cellphone: params[:cellphone])
      if user
        { error: 'Já existe um usuário com esse telefone.' }
      else
        user = User.find_by(cpf: params[:cpf])
        if user
          { error: 'Já existe um usuário com esse cpf.' }
        else
          nil
        end
      end
    end
  end

  def create_user(user_params, address_params, params)
    User.transaction do
      @user = User.new(user_params)
      @user.activated = true if @user.user_type == "user"

      if @user.save
        @user.addresses.build(address_params)
        
        # informações de cobrança da Wirecard
        if address_params
          @user.cep = address_params[:cep]
          @user.rua = address_params[:street]
          @user.estado = address_params[:state]
          @user.bairro = address_params[:district]
          @user.cidade = address_params[:city]
          @user.numero = address_params[:number]
          @user.complemento = address_params[:complement]
        end

        if @user.save
          @user
        else
          raise ServicesModule::V2::ExceptionsModule::UserException.new(@user.errors)
        end
      else
        raise ServicesModule::V2::ExceptionsModule::UserException.new(@user.errors)
      end
    end
  end

  def update_user(user, user_params)
    if user.update(user_params)
      user
    else
      raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
    end
  end

  def activate_user(params)
    @user = User.find_by(cellphone: params[:cellphone])

    raise ServicesModule::V2::ExceptionsModule::UserException.new(nil, "Usuario não encontrado.") if @user.nil?

    if @user.update(activated: params[:activated])
      nil
    else
      raise ServicesModule::V2::ExceptionsModule::UserException.new(@user.errors)
    end
  end

  def get_profile_photo(user)
    if user.user_profile_photo
      user.user_profile_photo
    else
      nil
    end
  end

  def set_profile_photo(user, params)
    @profile_photo = user.user_profile_photo

    if !@profile_photo
      @profile_photo = UserProfilePhoto.new
    end

    @profile_photo.photo.attach(image_io(params[:profile_photo]))
    user.user_profile_photo = @profile_photo

    if user.save
      @profile_photo
    else
      raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
    end
  end

  def update_player_id(user, params)
    if params[:player_id].nil? || params[:player_id].empty? || params[:player_id].length < 10
      raise ServicesModule::V2::ExceptionsModule::UserException.new(nil, "Player id inválido")
    end

    @another_users = User.where("player_ids @> ARRAY[?]::varchar[]", [params[:player_id]]).where.not(id: user.id)
    
    user.player_ids = [params[:player_id]] unless user.player_ids.include? params[:player_id]

    if @another_users.length > 0
      User.transaction do
        @another_users.each do |another_user|
          another_user.player_ids.delete params[:player_id]
          
          if !another_user.save
            raise ServicesModule::V2::ExceptionsModule::UserException.new(another_user.errors, "falha ao processar o usuario #{another_user.id}")
          end
        end
        if !user.save
          raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors, "falha ao processar o usuario #{user.id}")
        end
      end
    elsif !user.save
      raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors, "falha ao processar o usuario #{user.id}")
    end
  end

  def remove_player_id(user, params)
    if params[:player_id]
      user.player_ids.delete params[:player_id]

      if !user.save
        raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
      end
    end
  end

  def generate_access_token_professional(params)
    begin
      response = @payment_gateway_service.generate_access_token_professional(params[:code])

      if !@user.update(
        { id_wirecard_account: response["moipAccount"]["id"],
          token_wirecard_account: response["access_token"],
          refresh_token_wirecard_account: response["refresh_token"],
          is_new_wire_account: false
        })
        raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
      end
    rescue ServicesModule::V2::ExceptionsModule::PaymentGatewayException => e
      raise ServicesModule::V2::ExceptionsModule::PaymentGatewayException.new(e.payment_errors)
    end
  end

  private

    def image_io(image)
      decoded_image = Base64.decode64(image[:base64])
      { io: StringIO.new(decoded_image), filename: image[:file_name] }
    end
end