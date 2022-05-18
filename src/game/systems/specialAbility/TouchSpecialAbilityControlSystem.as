package game.systems.specialAbility
{
	import ash.core.Engine;
	
	import game.nodes.specialAbility.PlayerSpecialAbilityNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class TouchSpecialAbilityControlSystem extends GameSystem
	{
		public function TouchSpecialAbilityControlSystem()
		{
			super(PlayerSpecialAbilityNode, updateNode);
			super._defaultPriority = SystemPriorities.inputComplete;
		}
		
		public function updateNode(node:PlayerSpecialAbilityNode, time:Number):void
		{
			var release:Boolean = (node.motionControl.inputStateChange && node.motionControl.inputActive);
			
			if(release)
			{
				var edgeMultiplier:int = 3;
				
				if(Math.abs(node.motionTarget.targetDeltaX) < node.edge.rectangle.right * edgeMultiplier && Math.abs(node.motionTarget.targetDeltaY) < node.edge.rectangle.bottom * edgeMultiplier)
				{
					node.specialAbilityControl.trigger = true;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
		}
	}
}