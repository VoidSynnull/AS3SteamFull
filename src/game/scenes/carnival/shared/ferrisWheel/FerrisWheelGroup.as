package game.scenes.carnival.shared.ferrisWheel {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HitType;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisArm;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisAxle;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisSwing;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisWheel;
	import game.scenes.carnival.shared.ferrisWheel.components.RotationTarget;
	import game.scenes.carnival.shared.ferrisWheel.components.StickToEntity;
	import game.scenes.carnival.shared.ferrisWheel.components.StickyPlatform;
	import game.scenes.carnival.shared.ferrisWheel.systems.FerrisWheelSystem;
	import game.scenes.carnival.shared.ferrisWheel.systems.RotationTargetSystem;
	import game.scenes.carnival.shared.ferrisWheel.systems.StickToEntitySystem;
	import game.scenes.carnival.shared.ferrisWheel.systems.StickyPlatformSystem;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;

	// Begin the madness.

	public class FerrisWheelGroup extends Group {

		//private var arms:Vector.<Entity>;
		private var swings:Vector.<Entity>;
		private var platforms:Vector.<Entity>;

		/**
		 * top platforms.
		 */
		private var topPlats:Vector.<Entity>;

		private var wheel:Entity;

		/**
		 * Used to create hits for swinging platforms. Then discarded.
		 */
		private var hitCreator:HitCreator;

		/**
		 * Axle entity for the wheel, needs to be reused in wheel arm entities.
		 */
		private var axle:FerrisAxle;

		/**
		 * If true, ferris wheel arms will be bitmapped by default.
		 */
		public var bitmapArms:Boolean = true;

		private var parentClip:DisplayObjectContainer;

		public function FerrisWheelGroup() {

			super();

			this.id = "ferrisGroup";

		} //

		public function start():void {

			this.addSystem( new FerrisWheelSystem(), SystemPriorities.postUpdate );
			this.addSystem( new RotationTargetSystem(), SystemPriorities.preUpdate );
			this.addSystem( new StickToEntitySystem(), SystemPriorities.postUpdate );
			this.addSystem( new StickyPlatformSystem(), SystemPriorities.moveComplete );

			this.hitCreator = null;

		} //

		public function beginCreate( parentClip:MovieClip, centerClip:DisplayObjectContainer, deg_per_sec:Number ):void {

			this.parentClip = parentClip;

			centerClip = DisplayUtils.convertToBitmapSprite( centerClip ).sprite;

			this.createFerrisWheel( centerClip.x, centerClip.y, deg_per_sec*Math.PI/180 );

			this.hitCreator = new HitCreator();

		} //

		public function getSwings():Vector.<Entity> {
			return this.swings;
		}

		public function getSwing( i:int ):Entity {

			return this.swings[ i ];

		} //

		public function getPlatform( platIndex:int ):Entity {

			return this.platforms[ platIndex ];

		} //

		/**
		 * useBitmap indicates all arms will share the same bitmapData.
		 * 
		 * armHitPrefix is optional platform hit for the ferris wheel arms.
		 */
		public function addArms( armPrefix:String="ferrisArm", useBitmap:Boolean=true, armHitPrefix:String="armPlat" ):void {

			var i:int = 0;
			var clip:MovieClip = parentClip[ armPrefix + i ];

			if ( clip == null ) {
				return;
			}

			if ( useBitmap ) {

				var bitmapData:BitmapData = createBitmap( clip );
				var bounds:Rectangle = clip.getBounds( clip );

			} //

			while ( clip ) {

				if ( useBitmap ) {
					this.createArm( this.replaceWithBitmap( clip, bitmapData, bounds ), parentClip[ armHitPrefix + i ]);
				} else {
					this.createArm( clip, parentClip[ armHitPrefix + i ] );

				}
				
				i++;
				clip = parentClip[ armPrefix + i ];
				
			} //

		} //

		public function addSwings( swingPrefix:String="ferrisSeat", useBitmap:Boolean=true, hitPrefix:String="seatPlat", topHitPrefix:String="topPlat" ):void {
			
			var i:int = 0;
			var clip:MovieClip = parentClip[ swingPrefix + i ];
			
			if ( clip == null ) {
				return;
			}

			if ( useBitmap ) {

				var bitmapData:BitmapData = createBitmap( clip );
				var bounds:Rectangle = clip.getBounds( clip );
				
			} //

			this.swings = new Vector.<Entity>();
			this.platforms = new Vector.<Entity>();
			this.topPlats = new Vector.<Entity>();

			while ( clip ) {

				if ( useBitmap ) {
					this.createSwing( this.replaceWithBitmap( clip, bitmapData, bounds ), parentClip[ hitPrefix + i ], parentClip[ topHitPrefix + i ] );
				} else {
					this.createSwing( clip, parentClip[ hitPrefix + i ], parentClip[ topHitPrefix + i ] );
				}

				i++;
				clip = parentClip[ swingPrefix + i ];

			} // while

		} //

		public function createFerrisWheel( x:Number, y:Number, rad_per_sec:Number ):void {

			this.axle = new FerrisAxle( x, y, 0 );

			var motion:Motion = new Motion();
			motion.rotationVelocity = rad_per_sec*(180/Math.PI);

			var target:RotationTarget = new RotationTarget();
			target.enabled = false;

			var sp:Spatial = new Spatial( x, y );
			sp._rotation = 0;

			var e:Entity = this.wheel = new Entity()
				.add( this.axle, FerrisAxle )
				.add( sp, Spatial )
				.add( new Display( new Sprite() ), Display )
				.add( new FerrisWheel(), FerrisWheel )
				.add( target, RotationTarget )
				.add( motion, Motion );

			this.addEntity( e );

		} //

		public function createArm( mc:DisplayObjectContainer, hitClip:MovieClip=null ):void {

			var e:Entity = new Entity()
				.add( new Spatial( mc.x, mc.y ), Spatial )
				.add( new Display( mc ), Display )
				.add( axle, FerrisAxle )
				.add( new FerrisArm(), FerrisArm );
			
			super.addEntity( e );

			mc.mouseChildren = mc.mouseEnabled = false;

			if ( hitClip ) {

				var hitEntity:Entity = hitCreator.createHit( hitClip, HitType.PLATFORM, null, this );
				hitEntity.add( new StickyPlatform() );
				hitEntity.add( new StickToEntity( e, hitClip.x - mc.x, hitClip.y - mc.y ), StickToEntity );

				var sleep:Sleep = hitEntity.get( Sleep );
				if ( sleep ) {
					sleep.ignoreOffscreenSleep = true;
				}

			} //

		} //

		public function createSwing( mc:DisplayObjectContainer, bottomHit:MovieClip=null, topHit:MovieClip=null ):void {

			var swing:FerrisSwing;

			mc.mouseChildren = mc.mouseEnabled = false;
			mc.parent.setChildIndex( mc, mc.parent.numChildren-1 );

			var e:Entity = new Entity()
				.add( new Spatial( mc.x, mc.y ), Spatial )
				.add( new Display( mc ), Display )
				.add( axle, FerrisAxle )
				.add( new Motion(), Motion )			// swings need independent motions.
				.add( new FerrisSwing(), FerrisSwing );
			
			super.addEntity( e );

			this.swings.push( e );

			var hitEntity:Entity;
			var sleep:Sleep;

			if ( bottomHit ) {

				hitEntity = hitCreator.createHit( bottomHit, HitType.PLATFORM, null, this, false );
				hitEntity.add( new StickyPlatform() );
				hitEntity.add( new StickToEntity( e, bottomHit.x - mc.x, bottomHit.y - mc.y ), StickToEntity );

				sleep = hitEntity.get( Sleep );
				if ( sleep ) {
					sleep.ignoreOffscreenSleep = true;
				}

				this.platforms.push( hitEntity );

			} //

			if ( topHit ) {

				hitEntity = hitCreator.createHit( topHit, HitType.PLATFORM, null, this, false );
				hitEntity.add( new StickyPlatform() );
				hitEntity.add( new StickToEntity( e, topHit.x - mc.x, topHit.y - mc.y ), StickToEntity );

				sleep = hitEntity.get( Sleep );
				if ( sleep ) {
					sleep.ignoreOffscreenSleep = true;
				}

				this.topPlats.push( hitEntity );

			} //

		} //
		
		
		/**
		 * disables platforms so player can fall freely through them to get the ticket.
		 */
		public function disablePlats():void{
			
			var entity:Entity
			for each(entity in platforms){
				Sleep(entity.get(Sleep)).sleeping = true;
			}
			
			for each(entity in topPlats){
				Sleep(entity.get(Sleep)).sleeping = true;
			}
			
		}
		/**
		 * restores platforms of the ferris wheel
		 */
		public function restorePlats():void{
			
			var entity:Entity
			for each(entity in platforms){
				Sleep(entity.get(Sleep)).sleeping = false;
			}
			
			for each(entity in topPlats){
				Sleep(entity.get(Sleep)).sleeping = false;
			}
			
		}

		/**
		 * ferris wheel rotates to an angle in radians and stops.
		 * 
		 * onArrive is a callback function: onArrive( ferrisWheelEntity )
		 */
		public function rotateTo( degrees:Number, onArrive:Function=null ):void {

			var target:RotationTarget = this.wheel.get( RotationTarget ) as RotationTarget;
			target.rotateTo( degrees, onArrive );

		}

		/**
		 * Changes the angular velocity by acceleration/decceleration.
		 * Not instantaneous.
		 */
		public function changeAngularVelocity( deg_per_sec:Number ):void {

			var target:RotationTarget = this.wheel.get( RotationTarget ) as RotationTarget;
			target.rotationVelocityTo( deg_per_sec );

		} //

		/**
		 * Instantly sets the angular velocity of the ferris wheel in degrees per second.
		 */
		public function setAngularVelocity( deg_per_sec:Number ):void {

			var motion:Motion = this.wheel.get( Motion ) as Motion;
			motion.rotationVelocity = deg_per_sec;

		} //

		public function getRotationVelocity():Number {

			return ( this.wheel.get( Motion ) as Motion ).rotationVelocity;

		} //

		/**
		 * ferris wheel slows to a stop.
		 */
		public function stop():void {

			var target:RotationTarget = this.wheel.get( RotationTarget ) as RotationTarget;
			target.rotationVelocity = 0;
			target.enabled = true;

		} //

		/**
		 * Axle to get ferris wheel center location.
		 */
		public function getAxle():FerrisAxle {
			return this.axle;
		} //

		/**
		 * Makes the player slip off the ferris wheel platforms when hit.
		 */
		public function makeSlipperyPlatforms():void {

			//var p:Platform;
			//var sp:StickyPlatform;

			for( var i:int = this.topPlats.length-1; i >= 0; i-- ) {

				//( this.topPlats[ i ].get( Platform ) as Platform ).stickToPlatforms = false;
				( this.topPlats[ i ].get( StickyPlatform ) as StickyPlatform ).motionFactorX = -0.1;

			} //

			for( i = this.platforms.length-1; i >= 0; i-- ) {

				//( this.platforms[ i ].get( Platform ) as Platform ).stickToPlatforms = false;
				( this.platforms[ i ].get( StickyPlatform ) as StickyPlatform ).motionFactorX = -0.1;
				
			} //

		} //

		private function createBitmap( clip:DisplayObject ):BitmapData {

			var saveRotate:Number = clip.rotation;
			clip.rotation = 0;
			var rect:Rectangle = clip.getBounds( clip );

			var bmd:BitmapData = new BitmapData( clip.width, clip.height, true, 0 );
			var mat:Matrix = new Matrix( 1, 0, 0, 1, -rect.left, -rect.top );

			bmd.draw( clip, mat, null, null, null, true );

			clip.rotation = saveRotate;

			return bmd;

		} //

		private function replaceWithBitmap( clip:DisplayObject, bmd:BitmapData, bounds:Rectangle ):Sprite {

			var s:Sprite = new Sprite();
			s.name = clip.name;

			var bitmap:Bitmap = new Bitmap( bmd, "auto", true );
			bitmap.x = bounds.left;
			bitmap.y = bounds.top;

			s.transform = clip.transform;
			s.addChild( bitmap );

			// swap.
			var parent:DisplayObjectContainer = clip.parent;
			var ind:int = parent.getChildIndex( clip );
			parent.removeChildAt( ind );
			parent.addChildAt( s, ind );

			return s;

		} //

		public override function destroy():void {

			//this.arms.length = 0;
			//this.swings.length = 0;
			//this.arms = null;

			this.swings = null;
			this.platforms = null;
			this.topPlats = null;

			this.wheel = null;

		} //

		/*public function initFerrisWheel( parentClip:MovieClip, centerX:Number, centerY:Number, rad_per_sec:Number, armPrefix:String="ferrisArm", swingPrefix:String="ferrisSwing",
		hitPrefix="ferrisPlat" ):void {
		
		this.createFerrisWheel( centerX, centerY, rad_per_sec );
		
		var i:int = 0;
		var clip:MovieClip = parentClip[ armPrefix + i ];
		
		var wrapper:BitmapWrapper;
		
		while ( clip ) {
		
		if ( this.bitmapArms ) {
		wrapper = DisplayUtils.convertToBitmapSpriteBasic( clip );
		} //
		
		this.createArm( wrapper.sprite );
		
		i++;
		clip = parentClip[ armPrefix + i ];
		
		} //
		
		i = 0;
		clip = parentClip[ swingPrefix + i ];
		while ( clip ) {
		
		this.createSwing( clip, parentClip[ hitPrefix + i ] );
		
		i++;
		clip = parentClip[ swingPrefix + i ];
		
		} //
		
		this.hitCreator = null;
		
		} // initFerrisWheel()*/

	} // End FerrisWheelGroup

} // End package