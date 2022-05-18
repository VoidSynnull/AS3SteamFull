package game.scenes.prison.yard.states
{
	import engine.components.OwningGroup;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.SceneUtil;
	
	public class SeagullEatingState extends MovieclipState
	{
		public function SeagullEatingState()
		{
			this.type = "eating";
		}
		
		override public function start():void
		{
			this.setLabel("eat");
			node.timeline.handleLabel("endpeck", endPeck, false);
			
			_timerDone = false;
			SceneUtil.addTimedEvent(node.entity.get(OwningGroup).group, new TimedEvent(1.5, 1, timerFinished));
		}
		
		private function endPeck():void
		{
			if(_timerDone && hop)
			{
				node.timeline.removeLabelHandler(endPeck);
				node.timeline.gotoAndPlay("stopeat");				
				var state:String = "hop";
				
				_totalHops++;
				if(_totalHops == 4)
				{
					state = MovieclipState.STAND;
				}
				
				node.timeline.handleLabel("idle", Command.create(node.fsmControl.setState, state));
			}
			else
			{
				node.timeline.gotoAndPlay("peck");
			}
		}
		
		private function timerFinished():void
		{
			_timerDone = true;
		}
		
		public var hop:Boolean = true;
		private var _totalHops:Number = 0;
		private var _timerDone:Boolean;
	}
}