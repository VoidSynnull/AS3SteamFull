package game.ui.login
{
	public class LoginResult
	{
		public function LoginResult()
		{
		}
		
		public static const USERNAME_EMPTY:String = "Please enter a username.";
		public static const PASSWORD_EMPTY:String = "Please enter a password.";
		public static const USERNAME_INVALID:String = "User not found.";
		public static const PASSWORD_INVALID:String = "Incorrect password.";
		public static const ERROR_LOGIN:String = "Login Error.";
		public static const NETWORK_ERROR:String = "There is a problem with the network, please try again later.";
		public static const NO_NETWORK:String = "No network connection.";
		public static const LOGIN_SUCCEEDED:String = "Login succeeded";
		public static const LOGIN_EXISTS:String = "Login exists";
		public static const LOADING_CHARACTER:String = "Loading character...";
		
		// reponses
		public static const ANSWER_OK:String = "ok";
		public static const ANSWER_WRONG_PASSWORD:String = "wrongpass";
		public static const ANSWER_NO_USER:String = "nologin";
		
	}
}