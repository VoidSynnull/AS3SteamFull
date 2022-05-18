// Used by:
// Card "shield" on con3 using item poptropicon_worldguy
// Card "old_shield" on con3 island using item poptropicon_saworldguy

package game.data.specialAbility.islands.poptropicon
{
	import flash.display.Graphics;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.MetaPart;
	import game.components.entity.character.part.PartLayer;
	import game.components.entity.character.part.item.ItemMotion;
	import game.components.hit.EntityIdList;
	import game.components.input.Input;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.data.animation.entity.character.Shield;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.con3.shared.rayReflect.ReflectToRayCollision;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	/**
	 * Hold shield up as defense
	 */
	public class HoldShield extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			var rig:Rig = node.entity.get( Rig );
			var item:Entity = rig.getPart( CharUtils.ITEM );
			
			var partLayer:PartLayer = item.get( PartLayer );
			partLayer.setInsert( CharUtils.ARM_FRONT );
			
			var clip:MovieClip = Display( item.get( Display )).displayObject;
			
			if( item.get( MetaPart ).currentData.asset == "poptropicon_worldguy" )
			{
				// check event
				var charged:Boolean = super.shellApi.checkEvent( "weapons_powered_up", "con3" );
				if(charged)
				{
					// glow
					clip.removeChild( clip[ "normal" ]);
				}
				else
				{
					clip.removeChild( clip[ "powered" ]);
				}
			}
			
			if(super.shellApi.island == "con3")
			{
				var shieldButton:Entity = super.group.getEntityById( "shieldButton" );
				var button:Button;
				if( shieldButton )
				{
					button = shieldButton.get( Button );
					button.isSelected = true;
				}
			}
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{			
				if(CharUtils.getStateType(node.entity) == CharacterState.STAND)
				{
					CharUtils.setAnim(node.entity, Shield);
					
					var timeline:Timeline = node.entity.get(Timeline);
					timeline.handleLabel("loop", addShieldDeflection);
					
					node.entity.group.shellApi.triggerEvent("shield_activated");
					
					SceneUtil.getInput(node.entity.group).inputDown.add(onDown);
					
					this.setActive(true);
				}
			}
		}
		
		private function addShieldDeflection():void
		{
			if(super.data.isActive)
			{
				var item:Entity = SkinUtils.getSkinPartEntity(super.entity, CharUtils.ITEM);
				item.add(new EntityIdList());
				
				var itemMotion:ItemMotion = item.get(ItemMotion);
				itemMotion.state = ItemMotion.NONE;
				
				item.get(Spatial).rotation = 135;
				
				var reflect:ReflectToRayCollision = new ReflectToRayCollision();
				var graphics:Graphics = reflect.shape.graphics;
				graphics.clear();
				graphics.beginFill(0x0000FF);
				graphics.drawRect(-75, -5, 200, 40);
				graphics.endFill();
				item.add(reflect);
			}
		}
		
		private function onDown(input:Input):void
		{
			if(super.data.isActive)
			{
				this.stopShield();
				
				SceneUtil.getInput(super.group).inputDown.remove(onDown);
				this.setActive(false);
			}
		}
		
		private function stopShield():void
		{
			var item:Entity = SkinUtils.getSkinPartEntity(super.entity, CharUtils.ITEM);
			item.remove(ReflectToRayCollision);
			
			var itemMotion:ItemMotion = item.get(ItemMotion);
			if(itemMotion)
			{
				itemMotion.state = ItemMotion.ROTATE_TO_SHOULDER;
			}
			
			CharUtils.stateDrivenOn(super.entity);
			
			super.shellApi.triggerEvent("shield_deactivated");
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void 
		{
			this.stopShield();
			var item:Entity = SkinUtils.getSkinPartEntity(node.entity, SkinUtils.ITEM);
			
			var partLayer:PartLayer = item.get( PartLayer );
			if(partLayer)// do not bother with this if char is being removed
				partLayer.setInsert( CharUtils.ARM_FRONT, false );
			
			if(super.shellApi.island == "con3")
			{
				var shieldButton:Entity = super.group.getEntityById( "shieldButton" );
				var button:Button;
				if( shieldButton )
				{
					button = shieldButton.get( Button );
					button.isSelected = false;
				}
			}
		}
	}
}