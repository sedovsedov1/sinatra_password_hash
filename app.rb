
def hash_password(password)                           # Функция получения хэша из пароля
	BCrypt::Password.create(password).to_s              # Возвращает строку = хэшу присланной строки
end

def test_password(password, hash)                     # Функция сравнения пароля и хэша
	BCrypt::Password.new(hash) == password              # password = строка, hash = хэш (строки)
end

User = Struct.new(:id, :username, :password_hash)     # User = новая структура (id, имя, хэш)
USERS = [                                             # USERS = массив структур типа User
	User.new(1, 'ivan', hash_password('111')),          # 1) 1, ivan, хэш(111)
	User.new(2, 'mary', hash_password('222')),          # 2) 2, mary, хэш(222)
	User.new(3, 'join', hash_password('333')),          # 3) 3, join, хэш(333)  
]

class AuthExample < Sinatra::Base          # Основной класс AuthExample, наследник Sinatra::Base
	enable :sessions                         # Включить сессии (один хеш на один сеанс) 

	get '/' do                               # Обработка '/'
		if current_user                        # Если метод-помощник current_user вернул true...
			erb :home                            # ...то вывести вьюху home
		else                                   # ...иначе сделать редирект на ввод логина/пароля
			redirect '/sign_in'
		end
	end

	get '/sign_in' do                        # Обработка '/sign_in' (вход пользователя)
		erb :sign_in                           # Вывести вьюху sign_in
	end

	post '/sign_in' do                                                    # Обработка post '/sign_in'
		user = USERS.find { |u| u.username == params[:username] }           # Находим пользователя, имя которого попытались ввести
		if user && test_password(params[:password], user.password_hash)     # Если такой пользователь есть и его пароль совпадает (хэшем) с введенным, то...
			session.clear                                                     # 1) очищаем текущую сессию (кто бы там не был сохранен)
			session[:user_id] = user.id                                       # 2) сохраняем туда нового человека (его id)
			redirect '/'                                                      # 3) редирект на главуню страницу 
		else                                                                # ...иначе
			@error = 'Username or password was incorrect'                     # 1) определяем ошибку входа
			erb :sign_in                                                      # 2) вызываем вьюху sign_in
		end
	end

	post '/create_user' do                                                # Обработка post '/create_user' 
		# Добавляем в массив USERS нового юзера (id = длина массива + 1, имя = присланное, хэш пароля = сгенерированный хэш пароля)
		USERS << User.new(USERS.size + 1, params[:username], hash_password(params[:password]))
		redirect '/'                                                        # редиректр на главную страницу  
	end

	post '/sign_out' do                      # Обработка post '/sign_out'
		session.clear                          # 1) очищаем текущую сессию (кто бы там не был)
		redirect '/sign_in'                    # 2) редирект на ввод логина/пароля
	end

	helpers do                               # Определение метода-помощника        
		def current_user                       # Имя метода = current_user
			if session[:user_id]                 # Если в сессии данного сеанса есть запись формата session[:user_id]...
				# ...то найти среди всех элементво массива USERS id юзера, который сейчас авторизован (1,2,3,...)
				USERS.find { |u| u.id == session[:user_id] }
			else
				# ...иначе вернуть nil (все равно конвертируется в false при проверке)
				nil
			end
		end
	end

end
