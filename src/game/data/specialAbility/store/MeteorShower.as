// Used by:
// Card 3089 using ability meteor_shower

package game.data.specialAbility.store 
{
	import flash.display.Shape;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.Emitter;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Angry;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.backlot.sunriseStreet.Systems.EarthquakeSystem;
	import game.scenes.backlot.sunriseStreet.components.Earthquake;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;

	/**
	 * Shake scene with red tint and angry avatar 
	 */
	public class MeteorShower extends SpecialAbility
	{
		private var screenEffects:ScreenEffects;
		private var meteors:Entity;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			screenEffects = new ScreenEffects(super.shellApi.screenManager.container, super.shellApi.viewportWidth, super.shellApi.viewportHeight, .5, 0XFF0066);
			screenEffects.hide();
			
			if ( !this.data.isActive )
			{
				var _parentEntity:Entity = node.entity
				CharUtils.setAnim( node.entity, Angry );
				Timeline(node.entity.get(Timeline)).handleLabel("ending", startEarthquake);
				
				CharUtils.lockControls( node.entity, true );
				this.setActive( true );
				
				// Add the earthquake system if it's not there
				if( !this.group.getSystem( EarthquakeSystem ) )
				{
					this.group.addSystem( new EarthquakeSystem() );
				}
				
				var spatial:Spatial = node.entity.get(Spatial);
				var shape:Shape = new Shape();
				shape.x = spatial.x;
				shape.y = spatial.y;
				var cameraShake:Entity = EntityUtils.createSpatialEntity(group, shape, node.entity.get(Display).container);
				cameraShake.add(new Earthquake(spatial,new Point(1,10),5,20)).add(new Id("cameraShake"));
				SceneUtil.setCameraTarget(Scene(super.group), cameraShake);
				
				screenEffects.fadeToBlack(1);
			}
		}
		
		private function startEarthquake():void
		{
			// RLH enable avatar to run around now (doesn't work)
			CharUtils.lockControls( this.entity, false, false );
			var emitter2D:Emitter2D = new Emitter2D();
			
			emitter2D.counter = new Steady(14);
			
			emitter2D.addInitializer(new ExternalImage("assets/specialAbility/objects/asteroid.swf", true));
			emitter2D.addInitializer(new Position(new LineZone(new Point(0, 0), new Point(this.shellApi.viewportWidth + 100, 0))));
			emitter2D.addInitializer(new Velocity(new RectangleZone(-800, 600, -400, 1600)));
			emitter2D.addInitializer(new Rotation(0, Math.PI * 2));
			emitter2D.addInitializer(new ScaleImageInit(0.5, 2));
			
			emitter2D.addAction(new DeathZone(new RectangleZone(-10, -10, this.shellApi.viewportWidth, this.shellApi.viewportHeight), true));
			emitter2D.addAction(new Move());
			
			meteors = EmitterCreator.create(this, this.shellApi.currentScene.overlayContainer, emitter2D);
			
			SceneUtil.addTimedEvent(super.group, new TimedEvent(6,1,earthQuakeFinished));
		}
		
		private function earthQuakeFinished():void
		{
			SceneUtil.setCameraTarget(Scene(super.group), super.entity);
			group.removeEntity(group.getEntityById("cameraShake"));
			
			screenEffects.fadeFromBlack(1);
			
			this.setActive( false );
			this.data.remove();
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			CharUtils.stateDrivenOn( node.entity );
			CharUtils.lockControls( node.entity, false, false );
			
			if(meteors)
			{
				Emitter(meteors.get(Emitter)).emitter.counter.stop();
				Emitter(meteors.get(Emitter)).remove = true;
				meteors = null;
			}
		}
	}
}
