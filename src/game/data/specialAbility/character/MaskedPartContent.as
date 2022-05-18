package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	
	public class MaskedPartContent extends SpecialAbility
	{
		public var _partType:String;
		public var _maskName:String;
		public var _maskedName:String;
		
		protected var part:Entity;
		protected var container:DisplayObjectContainer;
		protected var mask:DisplayObjectContainer;
		protected var masked:DisplayObjectContainer;
		
		public function MaskedPartContent()
		{
			super();
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			part = CharUtils.getPart(node.entity, _partType);
			container = EntityUtils.getDisplayObject(part);
			mask = container[_maskName];
			masked = container[_maskedName];
			masked.mask = mask;
		}
	}
}