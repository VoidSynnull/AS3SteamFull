package game.systems.hit
{
	import ash.core.Engine;
	
	import game.components.hit.WeaponControl;
	import game.nodes.hit.WeaponInputControlNode;
	import game.systems.GameSystem;
	
	public class WeaponInputMapSystem extends GameSystem
	{
		public function WeaponInputMapSystem()
		{
			super(WeaponInputControlNode, updateNode);
		}
		
		public function updateNode(node:WeaponInputControlNode, time:Number):void
		{
			var weaponControl:WeaponControl = node.weaponControl;
			
			if(weaponControl.fire && inputIsUp(node)) 
			{ 
				weaponControl.fire = false; 
			}
			else if(!weaponControl.fire && inputIsDown(node)) 
			{ 
				weaponControl.fire = true; 
			}
		}
		
		// uses either keyboard or button state to determine if weapon should fire
		private function inputIsUp(node:WeaponInputControlNode):Boolean
		{
			var keyIsUp:Boolean = false;
			
			if(node.weaponControlInput)
			{
				keyIsUp = node.interaction.keyIsUp == node.weaponControlInput.fireKey
			}
			
			return !node.interaction.isDown /*|| node.interaction.isOut*/ || keyIsUp;
		}
		
		private function inputIsDown(node:WeaponInputControlNode):Boolean
		{
			var keyIsDown:Boolean = false;
			
			if(node.weaponControlInput)
			{
				keyIsDown = node.interaction.keyIsDown == node.weaponControlInput.fireKey
			}
			
			return node.interaction.isDown || keyIsDown;
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(WeaponInputControlNode);
			super.removeFromEngine(systemManager);
		}
	}
}