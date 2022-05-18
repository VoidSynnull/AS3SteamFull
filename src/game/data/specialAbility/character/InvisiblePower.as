// Status: new and unused
// Usage: none

package game.data.specialAbility.character
{
	import com.poptropica.AppConfig;
	
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.data.animation.entity.character.Alerted;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	/**
	 * Make avatar invisible (web only since it uses glow filter) 
	 * @author uhockri
	 * 
	 * Optional params:
	 * startle			Boolean		Startle nearby NPCs when reappear (default is false)
	 */
	public class InvisiblePower extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if turning on
			if (!super.data.isActive)
			{
				super.setActive( true );
				if (AppConfig.mobile)
					node.entity.get(Display).alpha = 0.15;
				else
					node.entity.get(Display).displayObject.filters = [new GlowFilter(0x000000, 1, 4, 4, 1, 1, false, true)];
			}
			// if turning off
			else
			{
				super.setActive( false );
				if (AppConfig.mobile)
					node.entity.get(Display).alpha = 1.0;
				else
					node.entity.get(Display).displayObject.filters = [];
				
				// startle nearby npcs
				if (_startle)
				{
					var entityArray:Vector.<Entity> = CharacterGroup(group.getGroupById("characterGroup")).getNPCs(CharacterGroup.NEAREST, 200);
					if (entityArray.length != 0)
					{
						for each(var entity:Entity in entityArray)
						{
							CharUtils.setAnim(entity, Alerted);
							SkinUtils.setSkinPart( entity, "mouth", "ooh");
						}
					}
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.setActive( false );
			if (AppConfig.mobile)
				node.entity.get(Display).alpha = 1.0;
			else
				node.entity.get(Display).displayObject.filters = [];
		}
		
		public var _startle:Boolean = false;
	}
}