// Used by:
// Card 3342 using ability glitch

package game.data.specialAbility.store
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.mocktropica.mockLoadingScreen.components.PixelCollapseComponent;
	import game.scenes.mocktropica.mockLoadingScreen.systems.PixelCollapseSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	/**
	 * Pixel collapse glitch effect applied to scene
	 */
	public class GlitchPower extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				var container:DisplayObjectContainer = node.entity.get(Display).container;
				
				// lock controls
				SceneUtil.lockInput( super.group );
				
				//do the glitch effect
				super.group.addSystem(new PixelCollapseSystem(), SystemPriorities.move);
				
				var pixelCollapseClip:MovieClip = new MovieClip();
				pixelCollapseClip.x = 0;
				pixelCollapseClip.y = 0;
				Scene(super.group).overlayContainer.addChild(pixelCollapseClip);
				effectEntity = EntityUtils.createSpatialEntity(super.group, pixelCollapseClip);
				effectEntity.add(new Id("pixelCollapseEntity"));
				effectEntity.add(new PixelCollapseComponent(Display(effectEntity.get(Display)), super.shellApi.viewportWidth, super.shellApi.viewportHeight, 20));
				
				SceneUtil.addTimedEvent( super.group, new TimedEvent( 7.5, 1, Command.create( deactivate, node )));
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// unlock controls
			SceneUtil.lockInput( group, false );
			
			// remove effect entity
			if( effectEntity )
			{
				//group.removeSystem(PixelCollapseSystem as System); //this throws an error for some reason
				group.removeEntity(effectEntity);
			}
			
			super.setActive( false );
			
			group.shellApi.log("deactivate glitch power, random id: " + Math.round(Math.random()*1000));
		}

		private var effectEntity:Entity;
	}
}