// Used by:
// Card 2454 using item ad_desmond_whoopee
// Card 2478 using item ad_pranks_fart
// Card 2697 using item limited_whoopee

package game.data.specialAbility.character
{	
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.specialAbility.WhoopeeComponent;
	import game.creators.entity.EmitterCreator;
	import game.systems.SystemPriorities;
	import game.systems.specialAbility.character.WhoopeeCushionSystem;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	/**
	 * Place whoopee cushion on ground and farts when NPCs step on it
	 * 
	 * Optional params:
	 * numSounds		Number		Number of random sounds to play (default is zero)
	 * doAirEffect		Boolean		Whether to trigger air emitter effect (default is false)
	 * sprayOffsetX		Number		Offset for spray effect from center of item (default is 0)
	 * sprayOffsetY		Number		Offset for spray effect from center of item (default is 0)
	 * slip				Boolean		Avatar slips on placed item
	 * vSpeed			Number		vertical slip speed
	 * hSpeed			Number		horizontal slip speed
	 * spin				Number		spin
	 * vAccel			Number		vertical acceleration
	 */
	public class WhoopeeCushion extends PlaceObject
	{
		/**
		 * Extra processing for whoopee cushion
		 * @param groundEntity
		 */
		override protected function additionalSetup(groundEntity:Entity):void
		{
			// scale vertically is not slipping
			if (!_slip)
			{
				groundEntity.get(Spatial).scaleY = .8;
			}
		
			// if need air emitter effect
			if (_doAirEffect)
			{
				// set up emitter
				var emitter:Emitter2D = new Emitter2D();
				emitter.counter = new Steady( 0 );
				emitter.addInitializer( new ImageClass( Blob, [10, 0xEEEEEE], true ) );
				emitter.addInitializer( new AlphaInit( .25, .5 ));
				emitter.addInitializer( new Lifetime( .5, 1 )); 
				emitter.addInitializer( new Velocity( new LineZone( new Point( 15, 0 ), new Point( 20, 10 ))));
				emitter.addInitializer( new Position( new EllipseZone( new Point( _sprayOffsetX, _sprayOffsetY ), 0, 2 )));
				emitter.addAction( new Age( Quadratic.easeOut ));
				emitter.addAction( new Move());
				emitter.addAction( new ScaleImage( .7,.3 ));
				emitter.addAction( new Fade( .7, 0 ));
				emitter.addAction( new Accelerate( 30, -20 ));
				
				var emitterEntity:Entity = EmitterCreator.create( super.group, groundEntity.get( Display ).displayObject, emitter, 0, 0 );
			}
			
			// set up component
			var whoopeeCushion:WhoopeeComponent = new WhoopeeComponent();
			whoopeeCushion.emitterEntity = emitterEntity;
			whoopeeCushion.doAirEffect = _doAirEffect;
			whoopeeCushion.slip = _slip;
			whoopeeCushion.vSpeed = _vSpeed;
			whoopeeCushion.hSpeed = _hSpeed;
			whoopeeCushion.spin = _spin;
			whoopeeCushion.vAccel = _vAccel;
			
			// add component to item entity and add system
			groundEntity.add( whoopeeCushion );
			super.group.addSystem( new WhoopeeCushionSystem(), SystemPriorities.update );
			
			// add audio
			if (_audioPrefix)
			{
				whoopeeCushion.audioPrefix = _audioPrefix;
				whoopeeCushion.numberOfSounds = _numSounds;
			}
			groundEntity.add( new Audio() ).add( new AudioRange( 500, 0.01, 1 )).add( new Id( "whoopeeCushion" ));
		}
		
		public var _numSounds:Number = 0;
		public var _audioPrefix:String;
		public var _doAirEffect:Boolean = false;
		public var _sprayOffsetX:Number = 0;
		public var _sprayOffsetY:Number = 0;
		public var _slip:Boolean = false;
		public var _vSpeed:Number = 0;
		public var _hSpeed:Number = 0;
		public var _spin:Number = 0;
		public var _vAccel:Number = 0;
	}
}