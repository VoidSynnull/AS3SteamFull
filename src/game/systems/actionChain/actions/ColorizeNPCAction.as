package game.systems.actionChain.actions
{
	import flash.display.DisplayObject;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.nodes.specialAbility.SpecialAbilityNode;
	
	// Set NPC to solid color except for eyes
	public class ColorizeNPCAction extends ActionCommand
	{
		private var color:Number;
		
		/**
		 * Set NPC to solid color except for eyes
		 * @param color
		 */
		public function ColorizeNPCAction(character:Entity, color:uint)
		{
			this.entity = character;
			this.color = color;
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			// all parts except for mouth, eyes, hands, feet
			var partList:Array = [CharUtils.SHIRT_PART,
				CharUtils.PANTS_PART,
				CharUtils.FACIAL_PART,
				CharUtils.MARKS_PART,
				CharUtils.PACK,
				CharUtils.HAIR,
				CharUtils.ITEM,
				CharUtils.OVERPANTS_PART,
				CharUtils.OVERSHIRT_PART,
				CharUtils.ARM_BACK,
				CharUtils.ARM_FRONT,
				CharUtils.LEG_BACK,
				CharUtils.LEG_FRONT,
				CharUtils.BODY_PART,
				CharUtils.HEAD_PART];
			
			for each (var part:String in partList)
			{
				var partEntity:Entity = CharUtils.getPart(this.entity, part);
				if (partEntity)
				{
					var clip:DisplayObject = partEntity.get(Display).displayObject;
					ColorUtil.colorize(clip, color);
				}
			}
			
			// darken color
			var darkenedColor:Number = ColorUtil.darkenColor(color, 0.15);
			
			// for hands and feet
			partList = [CharUtils.HAND_BACK, CharUtils.HAND_FRONT, CharUtils.FOOT_BACK, CharUtils.FOOT_FRONT];
			for each (part in partList)
			{
				partEntity = CharUtils.getPart(this.entity, part);
				if (partEntity)
				{
					clip = partEntity.get(Display).displayObject;
					ColorUtil.colorize(clip, darkenedColor);
				}
			}
			
			callback();
		}
	}
}