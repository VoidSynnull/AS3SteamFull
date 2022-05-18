package game.scenes.cavern2.shared
{
	import game.scene.template.ActionsGroup;
	import game.scene.template.CavernScene;
	import game.scenes.cavern2.Cavern2Events;
	import game.systems.actionChain.ActionChain;
	
	public class Cavern2Scene extends CavernScene
	{
		protected var cavern2:Cavern2Events;
		protected var actions:ActionsGroup;
		
		public function Cavern2Scene()
		{
			super();
		}
		
		override public function loaded():void
		{
			cavern2 = shellApi.islandEvents as Cavern2Events;
			shellApi.eventTriggered.add(onEventTriggered);
			
			super.loaded();
		}
		
		override protected function addActions():void
		{
			super.addActions();
			actions = getGroupById(ActionsGroup.GROUP_ID) as ActionsGroup;
		}
		
		protected function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			// TODO Auto Generated method stub
			performAction(event);
		}
		
		protected function performAction(actionName:String, onComplete:Function = null):void
		{
			if(actions)
			{
				var chain:ActionChain = actions.getActionChain(actionName);
				if(chain)
				{
					chain.execute();
					chain.onComplete = onComplete;
				}
			}
		}
	}
}