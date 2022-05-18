package game.scenes.timmy.shared
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.Group;
	
	import game.data.specialAbility.character.objects.ImpactResponse;
	import game.util.SkinUtils;
	
	public class TotalImpactResponse extends ImpactResponse
	{
		private var _parent:Group;
		
		public function TotalImpactResponse()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer, parent:Group):void
		{
			this._parent = parent;
		}
		
		override public function activate(hitObject:Entity, projectile:Entity, callback:Function=null):void
		{	
			if(hitObject)
			{
				var id:Id = hitObject.get(Id);
				if(id && id.id == "total")
				{
					var player:Entity = _parent.shellApi.player;
					var item:* = SkinUtils.getSkinPart(player, SkinUtils.ITEM).value;
					
					if(item == "crispy_rice_treats")
					{
						this._parent.shellApi.triggerEvent("use_treats");
					}
					else if(item == "bonbons")
					{
						this._parent.shellApi.triggerEvent("use_bonbons");
					}
				}
			}
			
			if(callback != null)
			{
				callback();
			}
		}
	}
}