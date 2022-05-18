// Used by:
// Card 3348 using ability cold_wind

package game.data.specialAbility.store
{	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.group.Scene;
	
	import game.components.entity.character.BitmapCharacter;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.ParticleRain;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;

	/**
	 * Add particle rain to scene and make NPCs tremble
	 */
	public class ColdWindPower extends SpecialAbility
	{
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{	
				MotionUtils.zeroMotion( super.entity );
				SceneUtil.lockInput( super.group );
				
				CharUtils.stateDrivenOff( super.entity );
				
				super.setActive( true );
				setSnow();
				
				var inSceneNpcs:Vector.<Entity> = (super.group.getGroupById('characterGroup') as CharacterGroup).getCharactersInView();
				if (inSceneNpcs)
				{
					for(var i:int = 0; i < inSceneNpcs.length; i++ )
					{
						if (!inSceneNpcs[i].has(BitmapCharacter))
						{
							CharUtils.setAnim( inSceneNpcs[i], Tremble );
							SceneUtil.addTimedEvent( super.group, new TimedEvent( 5, 1, endTremble ) );
						}
					}
				}
			}
		}
		
		/**
		 * Set know effect 
		 */
		private function setSnow():void
		{
			var rain:ParticleRain = new ParticleRain();
			var startVelocity : Point = new Point( 200, 0 );
			var box:Rectangle = new Rectangle( 0, -100, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			var allowedZone : RectangleZone = new RectangleZone( -100, -100, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			var startZone : RectangleZone = new RectangleZone( -100, -100, 0, super.shellApi.viewportHeight );
			rain.init(box);			
			
			rain.counter = new TimePeriod(800,5);
			rain.addInitializer( new ChooseInitializer([new ImageClass(Blob, [3, _color], true)]));
			rain.addInitializer(new Position(allowedZone));
			rain.addInitializer(new Velocity(new LineZone(new Point(100, 0), new Point(300, 5))));
			
			rain.addAction(new Move());
			rain.addAction(new Rotate());
			rain.addAction(new Accelerate( 500, 10 ));
			rain.addAction(new DeathZone(allowedZone, true));
			
			_emitterEntity = EmitterCreator.create( super.group, Scene(super.group).overlayContainer, rain );
			
			SceneUtil.addTimedEvent( super.group, new TimedEvent( 5, 1, endSnow));
		}
		
		/**
		 * End snow effect 
		 */
		private function endSnow():void
		{
			SceneUtil.lockInput( super.group, false );
			super.setActive( false );
			// RLH remove special ability from profile (this fixes problem with getting triggered on every scene load)
			super.shellApi.specialAbilityManager.removeSpecialAbility(super.shellApi.player, super.data.id);
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			endTremble();
		}
		
		/**
		 * When tremble animation done 
		 */
		private function endTremble():void
		{
			var inSceneNpcs:Vector.<Entity> = (super.group.getGroupById('characterGroup') as CharacterGroup).getCharactersInView();
			if (inSceneNpcs)
			{
				for(var i:int = 0; i < inSceneNpcs.length; i++ )
				{
					if (!inSceneNpcs[i].has(BitmapCharacter))
					{
						CharUtils.setAnim( inSceneNpcs[i], Stand );
					}
				}
			}
		}
		
		private var _emitterEntity:Entity;
		private var _color:uint = 0xFFFFFF;
	}
}