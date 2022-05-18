package game.scenes.virusHunter.shared.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Interaction;
	
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.components.WeaponControlInput;
	import game.scenes.virusHunter.shared.nodes.WeaponInputControlNode;
	import game.systems.GameSystem;
	import game.util.PlatformUtils;
	
	public class WeaponInputMapSystem extends GameSystem
	{
		public function WeaponInputMapSystem()
		{
			super(WeaponInputControlNode, updateNode, nodeAdded, nodeRemoved);
		}
		
		public function updateNode(node:WeaponInputControlNode, time:Number):void
		{
			var activeWeapon:Entity = node.weaponSlots.active;
			
			if(activeWeapon)
			{
				var weaponControl:WeaponControl = activeWeapon.get(WeaponControl);
			
				if(weaponControl)
				{
					if(PlatformUtils.isMobileOS)
					{
						if(actionButtonInteraction)
						{
							if(weaponControl.fire && (!actionButtonInteraction.isDown)) { weaponControl.fire = false; }
							if(!weaponControl.fire && actionButtonInteraction.isDown) { weaponControl.fire = true; }
						}
					}
					else
					{
						if(weaponControl.fire && node.interaction.keyIsUp == node.weaponControlInput.fireKey) { weaponControl.fire = false; }
						if(!weaponControl.fire && node.interaction.keyIsDown == node.weaponControlInput.fireKey) { weaponControl.fire = true; }
					}

					/*if(node.interaction.isDown)
					{
						node.weaponControlInput.triggerWeaponSelection = true;
					}
					else
					{
						node.weaponControlInput.triggerWeaponSelection = false;
					}*/
				}
			}
		}
		
		private function nodeAdded(node:WeaponInputControlNode):void
		{
			node.interaction.down.add(triggerWeaponSelection);
		}
		
		private function triggerWeaponSelection(entity:Entity):void
		{
			var weaponControlInput:WeaponControlInput = entity.get(WeaponControlInput);
			weaponControlInput.triggerWeaponSelection = !weaponControlInput.triggerWeaponSelection;
		}
		
		private function nodeRemoved(node:WeaponInputControlNode):void
		{
			node.interaction.down.remove(triggerWeaponSelection);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			actionButtonInteraction = null;
			systemManager.releaseNodeList(WeaponInputControlNode);
			super.removeFromEngine(systemManager);
		}
		
		public var actionButtonInteraction:Interaction;
	}
}