package game.scenes.ftue.shared
{
	import engine.group.Group;
	
	import game.components.input.Input;
	import game.systems.entity.character.states.CharacterState;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class TapCheckGroup extends Group
	{
		public var tappedCorrectly:Signal;
		private var releasedInTime:Boolean;
		public static const GROUP_ID:String = "tapCheckGroup";
		public function TapCheckGroup()
		{
			super();
			tappedCorrectly = new Signal();
			id=GROUP_ID;
		}
		
		override public function added():void
		{
			var input:Input = shellApi.inputEntity.get(Input);
			input.inputDown.add(startCheck);
		}
		
		private function startCheck(input:Input):void
		{
			releasedInTime = true;
			SceneUtil.delay(this, CharacterState.CLICK_DELAY, releaseTooLate);
			input.inputUp.addOnce(checkIfReleasedInTime);
		}
		
		private function checkIfReleasedInTime(input:Input):void
		{
			trace(releasedInTime);
			if(releasedInTime)
				tappedCorrectly.dispatch();
		}
		
		private function releaseTooLate():void
		{
			releasedInTime = false;
		}
		
		override public function destroy():void
		{
			var input:Input = shellApi.inputEntity.get(Input);
			input.inputDown.remove(startCheck);
			tappedCorrectly.removeAll();
			tappedCorrectly = null;
			super.destroy();
		}
	}
}