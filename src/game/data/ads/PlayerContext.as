package game.data.ads {
	import flash.utils.Proxy;
	
	import game.util.ProxyUtils;
	import game.util.SkinUtils;

	/**
	 * PlayerContext formalizes the payload sent through
	 * SiteProxy's gatewayManager
	 * @author Rich Martin
	 * 
	 */
	public class PlayerContext
	{
	
		public static const DEFAULT_AGE:int			= 6;	// age in years
		public static const DEFAULT_GENDER:String	= ProxyUtils.GENDER_MALE;

		public var platform:String;			// 'Desktop/Laptop' | 'Amazon' | 'AndroidOS' | 'iOS' | 'Other'

		private var _age:int		= DEFAULT_AGE;	
		private var _gender:String	= DEFAULT_GENDER;
		private var _island:String	= '';		// island name (`islands.short_name`)
		private var _types:Array;				// campaign types to return (array of strings)
		private var _exclude:Array;				// array of excluded campaigns
	
		public function PlayerContext(age:int, gender:String, island:String, types:Array, exclude:Array)
		{
			_age = age;
	
			if(gender == '0' || gender == '1')
			{
				_gender = ProxyUtils.convertGenderFromAS2ToServerFormat(Number(gender));
			}
			else
			{
				_gender = ProxyUtils.convertGenderToServerFormat(gender);
			}
	
			_island = island;
			_types = types;
			_exclude = exclude;
		}
	
		public function get age():int			{ return _age; }
		public function get gender():String		{ return _gender; }
		public function get island():String		{ return _island; }
		public function get types():Array		{ return _types ? _types : [];}
		public function get exclude():Array		{ return _exclude ? _exclude : [];}
	
		public function toString():String
		{
			var s:String = '[PlayerContext';
			s += ' age: ' + _age;
			s += ' gender: ' + _gender;
			s += ' island: ' + _island;
			s += ' types: ' + _types.toString();
			s += ' exclude: ' + _exclude.toString();
			s += ']';
			
			return s;
		}
	}
}
