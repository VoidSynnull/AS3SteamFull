package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SkinUtils;
	
	/**
	 * Twirl a clip inside the item part in the hand using motion
	 * 
	 * Optional params:
	 * spinSpeed	Number		How fast the part will spin
	 * clipName		String		The name of the clip inside the item part we want to spin
	 */
	public class TwirlPartOfItem extends SpecialAbility
	{
		override public function destroy():void
		{
			partOfItemEntity = null;
		}
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			var partEntity:Entity = CharUtils.getPart(node.entity, SkinUtils.ITEM);
			
			if(partEntity)
			{
				var mc:MovieClip = partEntity.get(Display).displayObject.getChildByName(_clipName);
			
				if(mc)
				{
					partOfItemEntity = EntityUtils.createMovingEntity(node.entity.group, mc);
				}
				else
				{
					trace("TwirlPartOfItem :: Couldn't find movieclip");
					deactivate(node);
				}
			}
			else
			{
				trace("TwirlPartOfItem :: Couldn't find Item Part");
				deactivate(node);
			}
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(partOfItemEntity)
			{
				var motion:Motion = partOfItemEntity.get(Motion);
				
				if(!data.isActive)
				{
					setActive(true);
					motion.rotationVelocity = _spinSpeed;
				}
				else
				{
					setActive(false);
					MotionUtils.zeroMotion(partOfItemEntity, "rotation");
					partOfItemEntity.get(Spatial).rotation = 0;
				}
			}
		}
		
		public var _spinSpeed:Number = 800;
		public var _clipName:String = "active_obj";
		
		private var partOfItemEntity:Entity;
	}
}