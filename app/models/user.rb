class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable
  devise :recoverable, :rememberable, :trackable, :validatable

  NUS_PROVIDER_REGEX = /\ANUS\z/
  NUS_OPEN_ID_PREFIX_REGEX = /\Ahttps:\/\/openid.nus.edu.sg\//
  NUS_OPEN_ID_PREFIX = 'https://openid.nus.edu.sg/'

  before_validation :process_uid

  validates :email, presence: true,
            format: {with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\z/,
                     message: ': Invalid email address format'},
            uniqueness: {message: ': user email should be unique'}
  validates :user_name, presence: true
  validates :provider, presence: true
  validates :uid, presence: true,
            uniqueness: {scope: :provider,
                         message: ': An OpenID account can only be used for creating one account'}

  enum provider: [:provider_nil, :provider_NUS]

  def self.from_omniauth(auth)
    user = User.find_by(provider: User.get_provider_from_raw(auth.provider), uid: auth.uid)
    if not user.nil?
      return user
    end
    user = User.new(email: auth.info.email, uid: auth.uid, user_name: auth.info.name)
    user.clean_user_provider(auth.provider)
    user.password = Devise.friendly_token.first(8)
    user.save ? user : nil
  end

  def self.get_provider_from_raw(provider)
    if provider[NUS_PROVIDER_REGEX]
      self.providers[:provider_NUS]
    else
      self.providers[:provider_nil]
    end
  end

  def clean_user_provider(provider)
    self.provider = User.get_provider_from_raw(provider)
  end

  def process_uid
    if self.uid
      self.uid = self.uid.downcase
      if (not self.uid[NUS_OPEN_ID_PREFIX_REGEX])
        self.uid = NUS_OPEN_ID_PREFIX + self.uid
      end
    end
  end
end
