package game.scenes.virusHunter.heart.creator {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Children;
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.hit.BitmapHit;
	import game.components.hit.Hazard;
	import game.components.hit.MovieClipHit;
	import game.creators.scene.HitCreator;
	import game.scenes.virusHunter.heart.components.AngleHit;
	import game.scenes.virusHunter.heart.components.ArmSegment;
	import game.scenes.virusHunter.heart.components.Arrhythmia;
	import game.scenes.virusHunter.heart.components.HeartFat;
	import game.scenes.virusHunter.heart.components.Nerve;
	import game.scenes.virusHunter.heart.components.QuadVirus;
	import game.scenes.virusHunter.heart.components.QuadVirusBody;
	import game.scenes.virusHunter.heart.components.RigidArm;
	import game.scenes.virusHunter.heart.components.RigidArmMode;
	import game.scenes.virusHunter.heart.components.RigidArmTarget;
	import game.scenes.virusHunter.heart.components.SwapDisplay;
	import game.scenes.virusHunter.joesCondo.creators.ClipCreator;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;

	public class VirusCreator {

		private var group:Group;

		public function VirusCreator( group:Group ) {

			this.group = group;

		} //

		public function createVirus( container:MovieClip, virusClip:MovieClip ):Entity {

			var display:Display = new Display( virusClip, container );

			var spatial:Spatial = new Spatial( virusClip.x, virusClip.y );
			spatial.rotation = virusClip.rotation;

			var virus:QuadVirus = new QuadVirus();
			virus.body = makeVirusBody( virusClip["mainBody"] );

			var e:Entity = new Entity()
				.add( spatial )
				.add( display )
				.add( new Motion() )
				.add( new Id( "quadVirus" ) )
				.add( virus )
				.add( new Sleep() );

			group.addEntity( e );

			// children will hold the jointed arms.
			var children:Children = new Children();

			var arm:Entity = makeArm( virusClip, "topArm", e );
			children.children.push( arm );
			virus.pushArm( arm.get( RigidArm ) as RigidArm );

			arm = makeArm( virusClip, "botArm", e );
			children.children.push( arm );
			virus.pushArm( arm.get( RigidArm ) as RigidArm );

			arm = makeArm( virusClip, "leftArm", e );
			children.children.push( arm );
			virus.pushArm( arm.get( RigidArm ) as RigidArm );

			arm = makeArm( virusClip, "rightArm", e );
			children.children.push( arm );
			virus.pushArm( arm.get( RigidArm ) as RigidArm );

			e.add( children );

			return e;

		} // createVirus()

		public function makeVirusBody( clip:MovieClip ):Entity {

			var e:Entity = new Entity()
				.add( new QuadVirusBody() )
				.add( new Display( clip ) )
				.add( new Spatial( clip.x, clip.y ) )
				.add( new Id( clip.name ) );

			var damageTarget:DamageTarget = new DamageTarget();
			damageTarget.damageFactor = new Dictionary();
			damageTarget.maxDamage = 1;

			damageTarget.damageFactor[ WeaponType.SCALPEL ] = 1;

			e.add( damageTarget, DamageTarget );

			var hit:MovieClipHit = new MovieClipHit( EnemyType.ENEMY_HIT );
			hit.validHitTypes[ "shipMelee" ] = true;

			e.add( hit, MovieClipHit );

			group.addEntity( e );

			return e;

		} //

		public function makeArm( virusBase:MovieClip, armPrefix:String, ve:Entity ):Entity {

			var arm:RigidArm = new RigidArm();
			var segments:Vector.<ArmSegment> = makeArmSegments( virusBase, armPrefix );
			arm.segments = segments;

			// first segment.
			var segment:ArmSegment = segments[ 0 ];
			arm.startX = segment.x;
			arm.startY = segment.y;

			var e:Entity = new Entity()
				.add( new Spatial( segment.x, segment.y ), Spatial )
				.add( new Motion(), Motion )
				.add( new Id( armPrefix ), Id )
				.add( new Sleep(), Sleep )
				.add( arm, RigidArm )
				.add( new Parent( ve ) )
				.add( new RigidArmTarget(), RigidArmTarget )
				.add( new RigidArmMode(), RigidArmMode );

			group.addEntity( e );

			// make the last segment in the chain a weapon.
			makeSegmentWeapon( segments[ segments.length-1 ].entity );

			return e;

		} //

		private function makeArmSegments( baseClip:MovieClip, prefix:String ):Vector.<ArmSegment> {

			var i:int = 0;
			var clip:DisplayObjectContainer = baseClip[ prefix+i ];

			var segments:Vector.<ArmSegment> = new Vector.<ArmSegment>();
			var segment:ArmSegment, prev:ArmSegment;

			prev = new ArmSegment( clip );
			prev.baseTheta = prev.theta = prev.absTheta;
			segments.push( prev );

			group.addEntity( prev.entity );

			var dx:Number, dy:Number;			// used for radius computations.

			i++;
			clip = baseClip[ prefix + i ];
			while ( clip != null ) {

				segment = new ArmSegment( clip );
				segment.baseTheta = segment.theta = segment.absTheta - prev.absTheta;

				// Kind of an obnoxious place to do this, but its got to be done somewhere.
				group.addEntity( segment.entity );

				// Since the segments aren't perfectly aligned in the .fla, this value may need to be projected onto
				// the axis-line of the previous segment.
				dx = segment.x - prev.x;
				dy = segment.y - prev.y;
				prev.radius = Math.sqrt( dx*dx + dy*dy );

				segments.push( segment );
				prev = segment;

				i++;
				clip = baseClip[ prefix+i ];

			} //

			// determine the final segment's radius by its bounding box.
			// assume the radius is the right-limit of the un-rotated bounding box.
			var rect:Rectangle = prev.clip.getBounds( prev.clip );
			prev.radius = rect.right;

			return segments;

		} //

		/**
		 * Init the segment with any extra things we need and add the entity
		 * to the system.
		 */
	/*	private function initSegment( segment:ArmSegment ):void {

			var e:Entity = segment.entity;
			group.addEntity( e );

		} //*/

		private function makeParentChild( parentEntity:Entity, childEntity:Entity ):void {

			var children:Children = parentEntity.get( Children );
			if ( children ) {

				// Already has a children entity defined. Just add this entity to the list.
				children.children.push( childEntity );

			} else {

				children = new Children();
				children.children.push( childEntity );

				parentEntity.add( children, Children );

			} //

			var parent:Parent = childEntity.get( Parent );
			if ( parent != null ) {

				parent.parent = parentEntity;

			} else {

				parent = new Parent();
				parent.parent = parentEntity;
				childEntity.add( parent, Parent );

			} //

		} // makeParentChild()

		public function makeVirusFat( clip:MovieClip, hitClip:MovieClip=null ):Entity {

			var angle:Number = clip.rotation;
			clip.rotation = 0;

			/**
			 * The new fat animations actually have a default angle of about -84 degrees. This means
			 * these angle hits are much less accurate than they should be.
			 */
			var angleHit:AngleHit = ClipCreator.makeAngleHit( angle - 84, 0.98*clip.height, clip.width*0.94 );
			angleHit.rebound = 1.2;
			clip.rotation = angle;
			clip.gotoAndStop( 1 );

			/**
			 * this removes clip from the display hierarchy and puts the new bitmap in its place.
			 * a sprite will be placed at the clip's location and a bitmap will be placed within
			 * that sprite, but offset to match the old appearance.
			 */
			var sprite:Sprite = makeBitmapSprite( clip );

			var display:Display = new Display( sprite );
			var spatial:Spatial = new Spatial( sprite.x, sprite.y );

			var damage:DamageTarget = new DamageTarget();
			damage.damageFactor = new Dictionary();
			damage.maxDamage = 1;
			damage.damageFactor[WeaponType.SCALPEL] = 1;
			damage.hitParticleColor1 = 0xEDAD4E;
			damage.hitParticleColor2 = 0xCA9342;
			damage.hitParticleVelocity = .8;

			var hit:MovieClipHit = new MovieClipHit( EnemyType.ENEMY_HIT );
			hit.validHitTypes[ "shipMelee" ] = true;
			if ( hitClip != null ) {
				hit.pointHit = true;
				hit.shapeHit = true;
				hitClip.visible = false;
				hit.hitDisplay = hitClip;
			} //

			//hit.pointHit = true;
			//hit.shapeHit = true;

			var e:Entity = new Entity()
				.add( new HeartFat() )
				.add( new Id( clip.name ) )
				.add( damage )
				.add( hit )
				.add( new Sleep() )
				.add( display )
				.add( spatial, Spatial )
				.add( angleHit, AngleHit );

			var swap:SwapDisplay = new SwapDisplay( e, clip );
			swap.savePosition = true;
			e.add( swap, SwapDisplay );

			group.addEntity( e );

			return e;

		} // makeVirusFat()

		private function bitmapClip( displayObject:DisplayObject, transparent:Boolean=true, fill:Number=0 ):BitmapData {

			var offsetMatrix : Matrix = displayObject.transform.matrix;
			var displayObjectBounds:Rectangle = displayObject.getBounds( displayObject.parent );
			
			if ( displayObject.rotation != 0 )  {
				transparent = true;			// rotated clip must have transparency or it will get a black fill.
			}
			
			offsetMatrix.tx = -( displayObjectBounds.left - displayObject.x );
			offsetMatrix.ty = -( displayObjectBounds.top - displayObject.y );
			
			var bitmapData : BitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, transparent, fill);
			bitmapData.draw( displayObject, offsetMatrix );

			return( bitmapData );

		} //

		private function makeBitmapSprite( clip:MovieClip ):Sprite {

			var bm:BitmapData = SimpleUtils.bitmapStageClip( clip );

			var bitmap:Bitmap = new Bitmap( bm );
			var bnds:Rectangle = clip.getBounds( clip.parent );
			bitmap.x = bnds.left - clip.x;
			bitmap.y = bnds.top - clip.y;

			var sprite:Sprite = new Sprite();
			sprite.addChild( bitmap );
			sprite.x = clip.x;
			sprite.y = clip.y;

			var ind:int = clip.parent.getChildIndex( clip );
			clip.parent.addChildAt( sprite, ind );
			clip.parent.removeChild( clip );

			return sprite;

		} //

		public function makeArrhythmia( target:MovieClip, animClip:MovieClip ):Entity {

			var damageTarget:DamageTarget = new DamageTarget();

			damageTarget.damageFactor = new Dictionary();
			damageTarget.maxDamage = 1;
			damageTarget.damageFactor[ WeaponType.SHOCK ] = 1;
			
			var e:Entity = new Entity()
				.add( new Arrhythmia( animClip ) )
				.add( new Sleep() )
				.add( new Display( target ), Display )
				.add( new Spatial( target.x, target.y ), Spatial )
				.add( damageTarget, DamageTarget )
				.add( new Id( target.name ), Id );

			var hit:MovieClipHit = new MovieClipHit( EnemyType.ENEMY_HIT );
			hit.validHitTypes[ "shipMelee" ] = true;

			e.add( hit, MovieClipHit );

			group.addEntity( e );

			return e;

		} //

		public function makeNerve( target:MovieClip, nerveNum:int ):Entity {

			var damageTarget:DamageTarget = new DamageTarget();

			damageTarget.damageFactor = new Dictionary();
			damageTarget.maxDamage = 1;
			damageTarget.damageFactor[ WeaponType.SHOCK ] = 1;

			var e:Entity = new Entity()
				.add( new Nerve( nerveNum ), Nerve )
				.add( new Display( target ), Display )
				.add( new Spatial( target.x, target.y ), Spatial )
				.add( damageTarget, DamageTarget )
				.add( new Id( target.name ), Id );

			var hit:MovieClipHit = new MovieClipHit( EnemyType.ENEMY_HIT );
			hit.validHitTypes[ "shipMelee" ] = true;

			e.add( hit, MovieClipHit );

			group.addEntity( e );

			return e;

		} //

		/**
		 * Make the part of the virus arm that both hits the player and serves as a target to be hit.
		 */
		private function makeSegmentWeapon( segment:Entity ):void {

			var hit:MovieClipHit = new MovieClipHit( EnemyType.ENEMY_HIT );
			segment.add( hit );
			hit.validHitTypes[ "ship" ] = true;

			var hazard:Hazard = new Hazard();
			hazard.damage = 0.2;

			segment.add( hazard );
			//segment.add( new Motion() );

		} //

		private function makeDamageTarget( entity:Entity ):DamageTarget {

			var damageTarget:DamageTarget = new DamageTarget();
			damageTarget.damageFactor = new Dictionary();
			damageTarget.maxDamage = 1;

			damageTarget.damageFactor[WeaponType.GUN] = 0.5;
			damageTarget.damageFactor[WeaponType.SCALPEL] = 1;
			damageTarget.damageFactor[WeaponType.SHOCK] = 1;

			entity.add( damageTarget, DamageTarget );

			var hit:MovieClipHit = new MovieClipHit( EnemyType.ENEMY_HIT );
			hit.validHitTypes[ "ship" ] = true;

			entity.add( hit );

			return damageTarget;

		} //

		private function changeClipParent( clip:DisplayObjectContainer, newParent:DisplayObjectContainer ):void {

			var p:Point = new Point( 0, 0 );
			clip.localToGlobal( p );
			newParent.globalToLocal( p );

			newParent.addChild( clip );
			clip.x = p.x;
			clip.y = p.y;

		} // changeClipParent()

		private function bitmapSegment( segment:MovieClip ):Sprite {

			var angle:Number = segment.rotation;
			segment.rotation = 0;

			var rect:Rectangle = segment.getBounds( segment );
			var matrix:Matrix = new Matrix( 1, 0, 0, 1, -rect.left, -rect.top );
			var bitmapData:BitmapData = new BitmapData( segment.width, segment.height, true, 0 );
			bitmapData.draw( segment, matrix );

			var bitmap:Bitmap = new Bitmap( bitmapData );
			bitmap.x = rect.left;
			bitmap.y = rect.top;

			var sprite:Sprite = new Sprite();

			sprite.addChild( bitmap );

			sprite.name = segment.name;
			sprite.x = segment.x;
			sprite.y = segment.y;
			sprite.rotation = angle;

			segment.parent.addChild( sprite );
			segment.parent.removeChild( segment );

			return sprite;

		} //

	} // End VirusCreator

} // End package