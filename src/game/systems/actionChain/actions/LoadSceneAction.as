package game.systems.actionChain.actions
{
	import engine.group.Group;
	
	import game.data.scene.DoorData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	
	public class LoadSceneAction extends ActionCommand
	{
		private var doorData:DoorData;
		public function LoadSceneAction(scene:String, x:Number = NaN, y:Number = NaN, direction:String = null)
		{
			doorData = new DoorData();
			doorData.destinationScene = scene;
			doorData.destinationSceneX = x;
			doorData.destinationSceneY = y;
			doorData.destinationSceneDirection = direction;
			super();
		}
		
		override public function preExecute(_pcallback:Function, group:Group, node:SpecialAbilityNode=null):void
		{
			group.shellApi.loadScene(doorData);
			
			_pcallback();
		}
	}
}