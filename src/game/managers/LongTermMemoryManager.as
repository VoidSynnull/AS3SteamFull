package game.managers
{
	import flash.net.SharedObject;
	
	import engine.Manager;

	public class LongTermMemoryManager extends Manager
	{
		public function LongTermMemoryManager()
		{
			establishLSO();
		}
		
		// MOBILE SPECIFIC 
		// TODO :: Could be moved to mobile specific step/class
		private function establishLSO():void
		{
			_lso = SharedObject.getLocal("poptropica", "/");
			_devLso  = SharedObject.getLocal("poptropica_dev", "/");
			
			var defaultEmpty:Boolean = false;
			
			// If not found in global location, check default as well as previous locations.
			if(_lso.size == 0)
			{
				_lso = SharedObject.getLocal("poptropica");
				defaultEmpty = true;
				
				if(_lso.size > 0)
				{
					trace("LongTermMemoryManager :: found lso at default location");
				}
			}
			else
			{
				trace("LongTermMemoryManager :: found lso at global location");
			}
			
			if(_lso.size == 0)
			{
				getLSO("Shell.swf");
			}
			
			if(_lso.size == 0)
			{
				getLSO("IosShell.swf");
			}
			
			if(_lso.size == 0)
			{
				getLSO("MobileShell.swf");
			}
			
			if(defaultEmpty)
			{
				var backup:Object;
				
				if(_lso.size > 0)
				{
					backup = _lso.data.profiles;
				}
				
				_lso.clear();
				_lso = SharedObject.getLocal("poptropica", "/");
				
				if(backup != null)
				{
					_lso.data.profiles = backup;
					_lso.flush();
				}
				else
				{
					trace("LongTermMemoryManager :: No backup lso found.");
				}
			}
		}
		
		public function save(field:String, value:*):void
		{
			var fields:Array = field.split(".");
			
			if(fields.length == 1)
			{
				_lso.data[field] = value;
			}
			else if(fields.length == 2)
			{
				if(_lso.data[fields[0]] == null)
				{
					_lso.data[fields[0]] = new Object();
				}
				_lso.data[fields[0]][fields[1]] = value;
			}
			else if(fields.length == 3)
			{
				if(_lso.data[fields[0]][fields[1]] == null)
				{
					_lso.data[fields[0]][fields[1]] = new Object();
				}
				_lso.data[fields[0]][fields[1]][[fields[2]]] = value;
			}
			else if(fields.length == 4)
			{
				if(_lso.data[fields[0]][fields[1]][fields[2]] == null)
				{
					_lso.data[fields[0]][fields[1]][fields[2]] = new Object();
				}
				_lso.data[fields[0]][fields[1]][fields[2]][fields[3]] = value;
			}
			
			_lso.flush();
		}
		
		public function clear(field:String = null):void
		{
			if(field == null)
			{
				_lso.clear();
				_devLso.clear();
			}
			else
			{
				save(field, null);
			}
		}

		public function data(field:String):*
		{
			var fields:Array = field.split(".");
			
			if(fields.length == 1)
			{
				return(_lso.data[field]);
			}
			else if(fields.length == 2)
			{
				return(_lso.data[fields[0]][fields[1]]);
			}
			else if(fields.length == 3)
			{
				return(_lso.data[fields[0]][fields[1]][[fields[2]]]);
			}
			else if(fields.length == 4)
			{
				return(_lso.data[fields[0]][fields[1]][fields[2]][fields[3]]);
			}
		}
				
		public function setDevProperty(key:String, value:*):void
		{
			_devLso.data[key] = value;
			_devLso.flush();
		}
		
		public function getDevProperty(key:String):*
		{
			return(_devLso.data[key]);
		}
		
		public function addDevCommand(command:String):void
		{
			if(_devLso.data.commands == null)
			{
				_devLso.data.commands = new Array();
			}
			
			if(_devLso.data.commands.length > 0)
			{
				if(command != _devLso.data.commands[0])
				{
					_devLso.data.commands.unshift(command);
				}
			}
			else
			{
				_devLso.data.commands.unshift(command);
			}
		}
		
		public function clearDevCommandHistory():void
		{
			_devLso.clear();
		}
		
		public function get devCommandHistory():Array
		{
			return(_devLso.data.commands);
		}
		
		public function get devConsoleUnlocked():Boolean
		{
			//return(_devLso.data.unlocked); // old storage place
			//return(_devLso.data.gen2Unlocked);
			return false;
		}
		
		public function set devConsoleUnlocked(unlocked:Boolean):void
		{
			//_devLso.data.unlocked = unlocked; // old storage place
			//_devLso.data.gen2Unlocked = unlocked;
			_devLso.data.gen3Unlocked = false;
			_lso.flush();
		}
		
		private function getLSO(suffix:String):void
		{
			try
			{
				_lso = SharedObject.getLocal("poptropica", suffix);
			}
			catch(e:Error)
			{
				trace("LongTermMemoryManager :: Error getting lso " + suffix + " : "+ e);
			}
			
			if(_lso.size > 0)
			{
				trace("LongTermMemoryManager :: found lso at " + suffix + " location.");
			}
		}
		
		private var _lso:SharedObject;
		private var _devLso:SharedObject;
	}
}