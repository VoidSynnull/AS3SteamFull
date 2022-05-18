package game.scenes.mocktropica.shared.petStates
{
	import game.scenes.mocktropica.shared.components.Narf;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.DisplayUtils;
	
	public class PetEatState extends MovieclipState
	{
		public function PetEatState()
		{
			super.type = "eat";
		}
		
		override public function start():void
		{
			numChews = Math.random() * 2 + 4;
			currentChew = 0;
			
			super.setLabel("eat");
			DisplayUtils.moveToTop(node.display.displayObject);
			node.timeline.handleLabel("chew", petChew, true);
			node.timeline.handleLabel("swallow", swallowHandler, false);
			node.timeline.handleLabel("stand", moveToStand, true);
		}
		
		private function petChew():void
		{		
			var narf:Narf = node.entity.get(Narf);
			narf.petChew.dispatch();
		}
		
		private function swallowHandler():void
		{
			currentChew++;
			if(currentChew < numChews)
			{
				node.timeline.gotoAndPlay("chew");
			}
		}
		
		private function moveToStand():void
		{
			node.fsmControl.setState(MovieclipState.STAND);
		}
		
		private var numChews:Number;
		private var currentChew:Number = 0;
	}
}