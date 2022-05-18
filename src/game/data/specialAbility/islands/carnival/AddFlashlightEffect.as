// Used by:
// hauntedLab scene on carnival island

package game.data.specialAbility.islands.carnival
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Scene;
	
	import game.components.specialAbility.character.FlashlightEffect;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.SystemPriorities;
	import game.systems.specialAbility.character.FlashlightEffectSystem;
	import game.util.EntityUtils;
	
	/**
	 * Flashlight effect in scene
	 */
	public class AddFlashlightEffect extends SpecialAbility
	{
		private var effectEntity:Entity;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				super.setActive( true );
				
				// add flashlight system
				super.group.addSystem(new FlashlightEffectSystem(Scene(super.group)), SystemPriorities.render);
				
				var flashlightEffectOverlay:MovieClip = new MovieClip();
				Scene(super.group).overlayContainer.addChildAt(flashlightEffectOverlay, 0);
				effectEntity = EntityUtils.createSpatialEntity(super.group, flashlightEffectOverlay);
				effectEntity.add(new Id("flashlightEffectOverlay"));
				effectEntity.add(new FlashlightEffect(Display(effectEntity.get(Display)), 150, 0.8));
				
				Scene(super.group).overlayContainer.mouseEnabled = false;
				//scene.overlayContainer.mouseChildren = false; //need to keep this on so the inventory button works
				flashlightEffectOverlay.mouseEnabled = false;
				flashlightEffectOverlay.mouseChildren = false;
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// remove effect entity
			if( effectEntity )
				super.group.removeEntity(effectEntity);
			
			super.setActive( false );
		}
	}
}
