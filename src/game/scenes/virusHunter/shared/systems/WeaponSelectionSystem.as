package game.scenes.virusHunter.shared.systems
{
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	
	import game.components.entity.character.Player;
	import game.components.motion.RotateControl;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.nodes.ShipMotionNode;
	import game.scenes.virusHunter.shared.nodes.WeaponInputControlNode;
	import game.scenes.virusHunter.shared.nodes.WeaponSelectionNode;
	
	public class WeaponSelectionSystem extends ListIteratingSystem
	{
		public function WeaponSelectionSystem()
		{
			super(WeaponSelectionNode, updateNode, nodeAdded, nodeRemoved);
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_shipMotionNode = systemManager.getNodeList( ShipMotionNode );
			_weaponInputControlNodes = systemManager.getNodeList(WeaponInputControlNode);
			_allWeapons = systemManager.getNodeList( WeaponSelectionNode );
			
		}
		
		private function nodeAdded( node:WeaponSelectionNode ):void
		{
			closeCount ++;
			node.interaction.down.add(weaponTriggered);
		}
		
		private function weaponTriggered(entity:Entity):void
		{
			var weaponControl:WeaponControl = entity.get(WeaponControl);
			weaponControl.weaponTriggered = true;
		}
		
		private function nodeRemoved( node:WeaponSelectionNode ):void
		{
			closeCount --;
			node.interaction.down.remove(weaponTriggered);
		}
		
		private function updateNode(node:WeaponSelectionNode, time:Number):void
		{
			var inputControlNode:WeaponInputControlNode = _weaponInputControlNodes.head;
			var shipNode:ShipMotionNode = _shipMotionNode.head;
			
			var weapon:Weapon = node.weapon;
			var deltaX:Number;
			var deltaY:Number;
			
			var totalWeapons:uint;
			var currentWeapon:WeaponSelectionNode;
			
			if(!_closeSelection)
			{
				if( inputControlNode.motion.acceleration.length > 0 )
				{
					inputControlNode.weaponSlots.active.get(Weapon).state = weapon.ACTIVE;
					_closeSelection = true;
					
					totalWeapons = 0;
					currentWeapon = _allWeapons.head;
					do{
						totalWeapons ++;
						currentWeapon = currentWeapon.next;
					}while( currentWeapon );
					
					if( totalWeapons == 1 )
					{
						shipNode.ship.unlock = true;
						playAudio(inputControlNode.entity, "weaponSelected");
						node.rotateControl.manualTargetRotation = NaN;
					}
				}
			}
			
			if(inputControlNode.weaponControlInput.triggerWeaponSelection)
			{
				_closeSelection = false;

  				shipNode.ship.locked = true;
				inputControlNode.weaponSlots.shut = 0;
				
				if(weapon.state == weapon.INACTIVE)
				{
					weapon.state = weapon.EXPAND;
				}
				else if(weapon.state == weapon.ACTIVE)
				{
					node.rotateControl.manualTargetRotation = weapon.selectionRotation;
					weapon.state = weapon.SELECTION;
				}
				
				playAudio(inputControlNode.entity, "weaponSelect");
			}
			if(node.weaponControl.weaponTriggered)
			{
				inputControlNode.weaponControlInput.triggerWeaponSelection = false;
				
				node.weaponControl.weaponTriggered = false;
				
				weapon.state = weapon.ACTIVE;
				inputControlNode.weaponSlots.active = node.entity;
				node.rotateControl.manualTargetRotation = NaN;
				
				// ONLY PLAY THE WEAPON SELECTION SOUND IF THE USER SELECTED A WEAPON WHILE WEAPON SELECTION WAS OPEN
				//	CURRENTLY WILL PLAY IF YOU SPAM CLICK YOUR ACTIVE WEAPON
				if( !_closeSelection )
				{
					playAudio(inputControlNode.entity, "weaponSelected");
				}
				_closeSelection = true;
				
				if(weapon.type == WeaponType.SCALPEL)
				{
					playAudio(node.entity, "weaponFire", true);
				}
				
				if(inputControlNode.entity.get(Player) && shipNode.ship.locked )
				{
					group.shellApi.setUserField( (group.shellApi.islandEvents as VirusHunterEvents).WEAPON_FIELD, weapon.type, group.shellApi.island );
					
					totalWeapons = 0;
					currentWeapon = _allWeapons.head;
					do{
						totalWeapons ++;
						currentWeapon = currentWeapon.next;
					}while( currentWeapon );
					
					if( totalWeapons == 1 )
					{
						shipNode.ship.unlock = true;
					}
				}
			}
			
			switch(weapon.state)
			{
				case weapon.SELECTION :
					if(_closeSelection)
					{
						weapon.state = weapon.RETRACT;
						
						totalWeapons = 0;
						currentWeapon = _allWeapons.head;
						do{
							totalWeapons ++;
							currentWeapon = currentWeapon.next;
						}while( currentWeapon );
						
						if( totalWeapons == 1 )
						{
							weapon.state = weapon.ACTIVE;
						}
					}
					break;
				
				case weapon.EXPAND :
					node.sleep.sleeping = false;
					node.display.visible = true;
					
					deltaX = weapon.activeX - node.display.displayObject["body"].x;
					deltaY = weapon.activeY - node.display.displayObject["body"].y;
					
					node.display.displayObject["body"].x += deltaX * .2;
					node.display.displayObject["body"].y += deltaY * .2;
					
					if(Math.abs(deltaX) <= .3)
					{
						node.display.displayObject["body"].x = weapon.activeX;
						node.display.displayObject["body"].y = weapon.activeY;
						weapon.state = weapon.SELECTION;
					}
					break;
				
				case weapon.RETRACT :
					deltaX = -8 - node.display.displayObject["body"].x;
					deltaY = -node.display.displayObject["body"].y;
					
					node.display.displayObject["body"].x += deltaX * .2;
					node.display.displayObject["body"].y += deltaY * .2;
										
					if(Math.abs(deltaX) <= .3)
					{
						node.display.displayObject["body"].x = 0;
						node.display.displayObject["body"].y = 0;
						
						node.display.visible = false;
						weapon.state = weapon.INACTIVE;
						node.sleep.sleeping = true;
						
						inputControlNode.weaponSlots.shut++;
						
						if( inputControlNode.weaponSlots.shut == closeCount - 1 )
						{
							shipNode.ship.unlock = true;						
						}
					}
					
					if(weapon.type == WeaponType.SCALPEL)
					{
						stopAudio(node.entity, "weaponFire");
					}
					break;
				
				case weapon.ACTIVE :
					if( shipNode.ship.unlock )
					{
						var currentRotateControl:RotateControl = inputControlNode.weaponSlots.active.get(RotateControl);
						currentRotateControl.manualTargetRotation = NaN;

						// LOGIC TO USE THE SINGLETON USER FIELD TO DETERMINE WHICH IS YOUR ACTIVE WEAPON AND CLOSE ANY OTHERS THAT MAY HAVE RETAINED
						//	ACTIVE STATE FROM SPAM MOUSE AND SPACEBAR CLICKS
						currentWeapon = _allWeapons.head;
						var activeWeapons:int = 0;
						var activeWeapon:String;
						
						do
						{
							if( currentWeapon.weapon.state == weapon.ACTIVE )	
							{
								activeWeapons++;
							}
							totalWeapons ++;
							currentWeapon = currentWeapon.next;
						}while( currentWeapon );
						
						if( activeWeapons > 1 )
						{
							currentWeapon = _allWeapons.head;
							activeWeapon = group.shellApi.getUserField("activeWeapon", group.shellApi.island );
							
							do
							{
								if( activeWeapon != weapon.type  )	
								{
									weapon.state = weapon.RETRACT;
								}
								currentWeapon = currentWeapon.next;
							}while( currentWeapon );
						}
						
						// This is for after the hand cutscene where the WBCs steal all your items, will reequip the basic gun
						if( inputControlNode.weaponSlots.shut == closeCount - 1 || totalWeapons == 1 )
						{
							shipNode.ship.unlock = false;		
							shipNode.ship.locked = false;
						}
					}
					break;
			}
		}
		
		private function playAudio(entity:Entity, action:String, loop:Boolean = false):void
		{
			var audio:Audio = entity.get(Audio);
			var actions:Dictionary;
			var soundData:SoundData;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions[action];
				
				if(soundData != null)
				{			
					audio.play(soundData.asset, loop, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
				}
			}
		}
		
		private function stopAudio(entity:Entity, action:String):void
		{
			var audio:Audio = entity.get(Audio);
			var actions:Dictionary;
			var soundData:SoundData;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions[action];
				
				if(soundData != null)
				{			
					audio.stop(soundData.asset);
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(WeaponSelectionNode);
			systemManager.releaseNodeList(ShipMotionNode);
			_weaponInputControlNodes = null;
			_shipMotionNode = null;
			_allWeapons = null;
			super.removeFromEngine(systemManager);
		}
		
		private var closeCount:uint;
		private var _weaponInputControlNodes:NodeList;
		private var _shipMotionNode:NodeList;
		private var _allWeapons:NodeList;
		private var _closeSelection:Boolean = false;
	}
}