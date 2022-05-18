package engine.command
{
	import game.util.ClassUtils;
	
	import org.osflash.signals.Signal;

	public class LinearCommandSequence
	{
		public function LinearCommandSequence()
		{
			_commands = new Vector.<CommandStep>();
			this.completed = new Signal();
		}
		
		public function add(command:CommandStep):void
		{
			_commands.push(command);
		}
		
		public function start():void
		{
			_index = -1;
			advance();
		}
		
		/**
		 * Advance the sequence 
		 * @param jumpTo
		 * 
		 */
		private function advance( increment:int = 1 ):void
		{
			if( !isNaN( increment ) && increment > 0 )
			{
				_index += increment;
			}
			else
			{
				_index++;
			}
			
			if(_index < _commands.length)
			{
				var command:CommandStep = _commands[_index];
				
				command.completed.addOnce(advance);
				command.completedAll.addOnce(complete);
				
				trace("Commmand ::", _index + 1, "/", _commands.length, ClassUtils.getNameByObject(command).split("::")[1]);
				command.execute();
			}
			else
			{
				complete();
			}
		}
		
		private function complete():void
		{
			this.completed.dispatch();
		}
		
		public var completed:Signal;
		private var _commands:Vector.<CommandStep>;
		private var _index:int = -1;
	}
}