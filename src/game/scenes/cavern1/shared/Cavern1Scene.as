package game.scenes.cavern1.shared
{
	import game.scene.template.ActionsGroup;
	import game.scene.template.CavernScene;
	import game.scenes.cavern1.Cavern1Events;
	import game.systems.actionChain.ActionChain;
	
	public class Cavern1Scene extends CavernScene
	{
		protected var cavern1:Cavern1Events;
		protected var actions:ActionsGroup;
		
		public function Cavern1Scene()
		{
			super();
		}
		
		override public function loaded():void
		{
			cavern1 = shellApi.islandEvents as Cavern1Events;
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