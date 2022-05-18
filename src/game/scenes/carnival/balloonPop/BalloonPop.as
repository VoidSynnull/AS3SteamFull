package game.scenes.carnival.balloonPop {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	
	import game.components.ui.Cursor;
	import game.creators.ui.ButtonCreator;
	import game.data.display.BitmapWrapper;
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.scene.template.CameraGroup;
	import game.scene.template.GameScene;
	import game.scenes.carnival.CarnivalEvents;
	import game.scenes.carnival.midwayDay.MidwayDay;
	import game.scenes.carnival.midwayEvening.MidwayEvening;
	import game.scenes.carnival.midwayNight.MidwayNight;
	import game.scenes.carnival.shared.game3d.components.Camera3D;
	import game.scenes.carnival.shared.game3d.components.ClipReference;
	import game.scenes.carnival.shared.game3d.components.ConstantForce3D;
	import game.scenes.carnival.shared.game3d.components.Draggable3D;
	import game.scenes.carnival.shared.game3d.components.Frustum;
	import game.scenes.carnival.shared.game3d.components.Hit3D;
	import game.scenes.carnival.shared.game3d.components.Motion3D;
	import game.scenes.carnival.shared.game3d.components.Spatial3D;
	import game.scenes.carnival.shared.game3d.geom.Box3D;
	import game.scenes.carnival.shared.game3d.systems.ConstantForceSystem;
	import game.scenes.carnival.shared.game3d.systems.Depth3DSystem;
	import game.scenes.carnival.shared.game3d.systems.Drag3DSystem;
	import game.scenes.carnival.shared.game3d.systems.Hit3DSystem;
	import game.scenes.carnival.shared.game3d.systems.Motion3DSystem;
	import game.scenes.carnival.shared.game3d.systems.Render3DSystem;
	import game.scenes.carnival.shared.game3d.utils.Game3DUtils;
	import game.components.entity.VariableTimeline;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.scenes.virusHunter.condoInterior.components.SimpleUpdater;
	import game.scenes.virusHunter.condoInterior.systems.SimpleUpdateSystem;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.util.AudioUtils;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	
	public class BalloonPop extends Scene {

		/**
		 * These numbers determine dart effects/scaling while dart is being held and dragged.
		 */
		private const MIN_DART_SKEW:Number = 0.5;
		private const MAX_DART_SKEW:Number = 1;
		private const MAX_DART_ROTATE:Number = 16;

		/**
		 * Hit3D types for the purposes of this scene.
		 */
		private const DART_HIT:int = 1;
		private const BALLOON_HIT:int = 2;
		private const WALL_HIT:int = 4;
		private const FLOOR_HIT:int = 8;

		private const FOCUS_DEPTH:Number = -1000;

		/**
		 * Z coordinate for balloons.
		 */
		private const BALLOON_Z:int = 700;

		private const MAX_DRAG_COORDS:int = 3;
		private const MIN_THROW_SPEED:Number = 100;
		private const MAX_THROW_SPEED:Number = 300;

		private var myEvents:CarnivalEvents;
		private var cameraSystem:CameraSystem;

		private var cam3D:Camera3D;

		//private var balloons:Vector.<Entity>;
		private var darts:Vector.<Entity>;
		private var curDart:Entity;

		/**
		 * Track coordinates when a dart is being dragged to calaculate the trajectory
		 * the dart should have when its thrown/released. For efficiency, x,y numbers
		 * are stored as consecutive x,y pairs in the same vector. [x1,y1,x2,y2,x3,y3]
		 */
		private var dragCoords:Vector.<Number>;

		private var dartsSharp:Boolean = false;
		private var dartPrefix:String = "blunt";			// prefix to add before dart frames. blunt or sharp.

		/**
		 * The clip containing all the objects that will be controlled by the 3D systems.
		 */
		private var view3D:Sprite;

		/**
		 * Entity for all the mouse inputs.
		 */
		private var inputEntity:Entity;

		private var playerEntity:Entity;

		private var dartsUsed:int = 0;
		private var endTimer:Number = 0;

		private var gameWon:Boolean = false;

		/**
		 * Used to compute throw velocities.
		 */
		private var prevX:Number;
		private var prevY:Number;

		private var closeButton:Entity;

		public function BalloonPop() {

			super();

		} //

		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void {

			super.groupPrefix = "scenes/carnival/balloonPop/";			
			super.init( container );

			this.load();

		} //

		// initiate asset load of scene configuration.
		override public function load():void {

			this.dragCoords = new Vector.<Number>();

			super.shellApi.fileLoadComplete.addOnce( this.loadAssets );
			super.loadFiles( [GameScene.SCENE_FILE_NAME,GameScene.SOUNDS_FILE_NAME] );

		} // load()

		protected function loadAssets():void {

			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData( GameScene.SCENE_FILE_NAME );

			super.sceneData = parser.parse( sceneXml );
			super.shellApi.fileLoadComplete.addOnce( this.loaded );
			super.loadFiles( super.sceneData.assets );

		} //

		protected function loadCloseButton( baseClip:MovieClip ):void {

			this.closeButton = ButtonCreator.loadCloseButton( this, baseClip, handleCloseClicked, DisplayPositions.TOP_RIGHT );

		}

		private function handleCloseClicked( ...args ):void {

			AudioUtils.play(this, SoundManager.EFFECTS_PATH + SoundManager.STANDARD_CLOSE_CANCEL_FILE);
			this.endGame( false );

		}

		// all assets ready
		override public function loaded():void {
			
			this.myEvents = this.events as CarnivalEvents;
			
			super.addSystem( new Render3DSystem(), SystemPriorities.preRender );			// needed for popup twween.
			// it shouldn't matter if the depth swapping happens before or after x,y positioning, i think.
			this.addSystem( new Depth3DSystem(), SystemPriorities.render );

			this.addSystem( new Motion3DSystem(), SystemPriorities.update );
			super.addSystem( new InteractionSystem(), SystemPriorities.update );	

			this.addSystem( new ConstantForceSystem(), SystemPriorities.preUpdate );
			this.addSystem( new VariableTimelineSystem(), SystemPriorities.timelineControl );

			this.addSystem( new Drag3DSystem(), SystemPriorities.preUpdate );

			super.addSystem( new Hit3DSystem(), SystemPriorities.checkCollisions );

			//this.addSystem( new BoundsCheckSystem(), SystemPriorities.preRender );
			//this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );

			var cameraGroup:CameraGroup = new CameraGroup();

			// This method of cameraGroup does all setup needed to add a camera to this scene.  After calling this method you just need to assign cameraGroup.target to the spatial component of the Entity you want to follow.
			// NOTE : The scene width/height MUST be bigger than the viewport when at the minimum scale.
			cameraGroup.setupScene( this, 1 );
			this.cameraSystem = this.shellApi.camera;

			this.create3DView();

			this.dartsSharp = super.shellApi.checkHasItem( this.myEvents.SHARPENED_DART );//super.shellApi.checkEvent( this.myEvents.SHARPENED_DART );
			if ( this.dartsSharp ) {
				this.dartPrefix = "sharp";
			}

			/**
			 * Here we need to move the darts,balloons from the interactive layer to the view3d layer. the reason for this is
			 * that every clip on the view3d layer has to have a well-defined spatial3D. Otherwise depth sorting messes up
			 * after you add the first spatial3D and it tries to do a depth-sort on clips with no spatial.
			 */
			var interactive:MovieClip = ( super.getEntityById( "interactive" ).get( Display ) as Display ).displayObject;

			// set up the stupid foreground to match the day and then place it in the correct 3dView position.
			this.initForeground( interactive );

			this.initDarts( interactive );
			this.initBalloons( interactive );
			this.initWalls();

			this.loadCloseButton( interactive );

			this.inputEntity = this.shellApi.inputEntity;

			super.loaded();

		} // loaded()

		/**
		 * Dart hit a balloon.
		 */
		public function onHitObject( dart:Entity, hitEntity:Entity ):void {

			var motion:Motion3D = this.curDart.get( Motion3D ) as Motion3D;
			motion.velocity.x *= -0.2;
			motion.velocity.y *= -0.2;
			motion.velocity.z *= -0.1;

			var type:int = ( hitEntity.get(Hit3D) as Hit3D ).hitType;
			if ( type == this.BALLOON_HIT ) {

				( dart.get(Hit3D) as Hit3D ).hitCheck &= ~this.BALLOON_HIT;

				if ( this.dartsSharp ) {
					this.destroyBalloon( hitEntity );
				} else {
					this.wobbleBalloon( hitEntity );
				} //

			} else if ( type == this.WALL_HIT ) {

				/**
				 * Ideally the hit system should move the dart outside the wall area -- add that when we actually need it.
				 * For now, remove the wall hit code from the hitCheck mask so the dart doesn't hit the wall again.
				 */
				( dart.get(Hit3D) as Hit3D ).hitCheck &= ~this.WALL_HIT;
				if ( this.dartsSharp ) {

					// stick to wall.
					dart.remove( Motion3D );
					dart.remove( Hit3D );
					this.checkDartsUsed();

				} //

			} else if ( type == this.FLOOR_HIT ) {

				this.removeEntity( dart );
				for( var i:int = darts.length-1; i >= 0; i-- ) {
					if ( darts[i] == dart ) {
						darts[i] = darts[ darts.length-1 ];
						darts.pop();
						break;
					}
				} //
				this.checkDartsUsed();

			} //

		} // onHitObject()

		private function checkDartsUsed():void {

			if ( ++ this.dartsUsed == 3 ) {

				// END THE GAME.
				var viewLayer:Entity = super.getEntityById( "view3d" );
				viewLayer.add( new SimpleUpdater( this.timeEnd ), SimpleUpdater );
				this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );
				
			} //

		} //

		private function timeEnd( time:Number ):void {

			this.endTimer += time;

			if ( this.endTimer >= 1.5 ) {

				var viewLayer:Entity = super.getEntityById( "view3d" );
				viewLayer.remove( SimpleUpdater );

				this.endGame( this.gameWon );

			} //

		} //

		private function endGame( wonGame:Boolean=false ):void {

			if ( wonGame ) {
			//	trace( "WON GAME" );
				this.shellApi.completeEvent( this.myEvents.WON_BALLOON_POP );
			}

			if ( this.shellApi.checkEvent( this.myEvents.SET_NIGHT ) ) {
				this.shellApi.loadScene( MidwayNight, 2243, 1950 );
			} else if ( this.shellApi.checkEvent( this.myEvents.SET_EVENING ) ) {
				this.shellApi.loadScene( MidwayEvening, 2243, 1950 );
			} else {
				this.shellApi.loadScene( MidwayDay, 2243, 1950 );
			} //

		} //

		private function destroyBalloon( b:Entity ):void {

			var hit:Hit3D = b.get( Hit3D );
			hit.hitType = 0;

			//b.remove( Hit3D );
			//b.remove( Spatial3D );

			var soundNum:int = Math.floor( 3*Math.random() ) + 1;
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "balloon_pop_0" + soundNum + ".mp3" );

			var tl:VariableTimeline = b.get( VariableTimeline );
			tl.gotoAndStop( "pop" );

			var viewLayer:Entity = super.getEntityById( "view3d" );
			this.gameWon = true;
			viewLayer.add( new SimpleUpdater( this.timeEnd ), SimpleUpdater );

			for( var i:int = darts.length-1; i >= 0; i-- ) {

				darts[i].remove( Draggable3D );

			} //

			this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );

		} //

		private function wobbleBalloon( b:Entity ):void {

			var soundNum:int = Math.floor( 2*Math.random() ) + 1;
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "balloon_bounce_0" + soundNum + ".mp3" );

			var tl:VariableTimeline = b.get( VariableTimeline );
			tl.gotoAndPlay( 1 );

			( b.get(ClipReference) as ClipReference ).clip.gotoAndPlay( 1 );

		} //

		/**
		 * Set the parent displayObject PerspectiveProjection
		 */
		private function create3DView():void {

			var viewLayer:Entity = super.getEntityById( "view3d" );

			/**
			 * Need to add a new clip because the viewLayer keeps getting its position set to 0,0 by the Scene-camera system.
			 */
			this.view3D = new Sprite();
			( Display( viewLayer.get(Display) ).displayObject as DisplayObjectContainer ).addChild( this.view3D );

			this.view3D.x = this.cameraSystem.x + this.cameraSystem.viewportWidth/2;
			this.view3D.y = this.cameraSystem.y + this.cameraSystem.viewportHeight/2;

			var e:Entity = new Entity();
			e.add( new Display( this.view3D ), Display );

			this.cam3D = new Camera3D();
			e.add( cam3D, Camera3D );
			e.add( new Frustum( 0, 0, this.FOCUS_DEPTH ), Frustum );

			this.addEntity( e );

			//change tooltip to "target"
			Cursor( super.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.TARGET;

			// View stuff.
			( super.getGroupById( "cameraGroup" ) as CameraGroup ).setTarget( new Spatial( 0, 0 ), true );

		} //

		private function initForeground( baseClip:MovieClip ):void {

			var fg:MovieClip = baseClip.fg;

			if ( super.shellApi.checkEvent( this.myEvents.SET_NIGHT ) ) {
				fg.gotoAndStop( "night" );
			} else if ( super.shellApi.checkEvent( this.myEvents.SET_EVENING ) ) {
				fg.gotoAndStop( "evening" ); 
			} else {
				fg.gotoAndStop( "day" );
			} // end-if.

			// bitmap the stupid stupid foreground thing.
			var bw:BitmapWrapper = DisplayUtils.convertToBitmapSprite( fg );

			var loc:Spatial3D = new Spatial3D( bw.sprite.x - view3D.x, bw.sprite.y - view3D.y, 3 );
			loc.enableScaling = false;

			var e:Entity = Game3DUtils.makeObject( bw.sprite, loc, null );


			this.addEntity( e );


		} //

		private function initDarts( baseClip:MovieClip ):void {

			this.darts = new Vector.<Entity>();

			var i:int = 0;
			var mc:MovieClip = baseClip[ "dart"+i++ ];

			var e:Entity;
			var loc:Spatial3D;
			var hit:Hit3D;
			var drag:Draggable3D;

			while ( mc ) {

				loc = new Spatial3D( mc.x - view3D.x, mc.y - view3D.y, 4 );
				loc.enableScaling = false;
				hit = new Hit3D( new Box3D( 20, 20, mc.height ), this.DART_HIT );
				hit.onHit.add( this.onHitObject );

				e = Game3DUtils.makeObject( mc, loc, hit );

				drag = new Draggable3D();
				drag.onStartDrag.add( this.startDragDart );
				drag.onEndDrag.add( this.throwDart );

				e.add( drag, Draggable3D );
				e.add( new Interaction(), Interaction );

				this.addEntity( e );

				this.darts.push( e );

				if ( this.dartsSharp ) {
					mc.gotoAndStop( 1 );
				} else {
					mc.gotoAndStop( 0 );
				} //

				mc = baseClip[ "dart"+i++ ];

			} //

		} //

		private function initBalloons( baseClip:MovieClip ):void {

			//this.balloons = new Vector.<Entity>();

			var i:int = 0;
			var mc:MovieClip = baseClip[ "balloon"+i ];

			var e:Entity;
			var loc:Spatial3D;
			var hit:Hit3D;
			var tl:VariableTimeline;

			var shadow:MovieClip;

			// the balloon art isn't scaled because the art is the correct size for the balloon Z.
			// the scale is needed to enlarge the hit box to the appropriate size.
			var scale:Number = this.cam3D.getScaleAtCameraZ( this.BALLOON_Z );

			while ( mc ) {

				loc = new Spatial3D( mc.x - view3D.x, mc.y - view3D.y, this.BALLOON_Z );

				// the balloon art is already at the correct scale so any more scaling would be bad.
				loc.enableScaling = false;

				// because the objects aren't scaled, the hit box of the balloons are actually proportionally larger.
				// multiply by smaller factor because using rects. should actually be using spheres. maybe ill change.
				hit = new Hit3D( new Box3D( 0.8*mc.width, 0.8*mc.height, 40 ), this.BALLOON_HIT );

				e = Game3DUtils.makeObject( mc, loc, hit );

				tl = new VariableTimeline( false );
				tl.onLabelReached.add( this.balloonLabelReached );
				e.add( tl, VariableTimeline );

				shadow = baseClip[ "shadow"+ i ];
				shadow.gotoAndStop( 0 );
				e.add( new ClipReference( shadow ), ClipReference );

				this.addEntity( e );
				//this.balloons.push( e );

				i++;
				mc = baseClip[ "balloon"+i ];

			} //

		} //

		private function initWalls():void {

			// BACK WALL
			var hit:Hit3D = new Hit3D( new Box3D(1000, 1000, 40 ), this.WALL_HIT );
			var e:Entity = Game3DUtils.makeObject( null, new Spatial3D( 0, 0, BALLOON_Z+40 ), hit );

			this.addEntity( e );

			// FLOOR
			hit = new Hit3D( new Box3D(1000, 40, 1000), this.FLOOR_HIT );
			e = Game3DUtils.makeObject( null, new Spatial3D( 0, 300, 150 ), hit );

			this.addEntity( e );

		} //

		private function balloonLabelReached( b:Entity, label:String ):void {

			if ( label == "wobbleEnd" ) {

				( b.get( VariableTimeline ) as VariableTimeline ).gotoAndStop( 0 );
				( b.get( ClipReference ) as ClipReference ).clip.gotoAndStop( 0 );

			} else if ( label == "pop" ) {

				// balloon popped.

				var shadow:MovieClip = ( b.get( ClipReference ) as ClipReference ).clip;
				shadow.parent.removeChild( shadow );

				b.remove( ClipReference );

			} //

		} //

		private function startDragDart( dart:Entity ):void {

			this.dragCoords.length = 0;

			var sp:Spatial3D = dart.get( Spatial3D ) as Spatial3D;
			sp.z = 0;

			( dart.get( Spatial ) as Spatial ).rotation = 0;

			sp.enableScaling = true;

			this.prevX = sp._cx;
			this.prevY = sp._cy;

			var drag:Draggable3D = dart.get( Draggable3D ) as Draggable3D;
			drag.onDrag.add( this.dragDart );

			var clip:MovieClip = ( dart.get(Display) as Display ).displayObject as MovieClip;
			clip.gotoAndStop( this.dartPrefix + "Throw" );

			this.setDartSkew( sp, clip.getChildByName("scaleClip") as MovieClip );

			this.curDart = dart;

		} //

		private function setDartSkew( dartSpatial:Spatial3D, scaleClip:MovieClip ):void {

			var ratio:Number = (dartSpatial.cx / 350);
			if ( ratio > 1 ) {
				ratio = 1;
			} else if ( ratio < -1 ) {
				ratio = -1;
			}

			if ( ratio < 0 ) {
				scaleClip.scaleX = this.MIN_DART_SKEW - ratio*( this.MAX_DART_SKEW-this.MIN_DART_SKEW );
			} else if ( ratio > 0 ) {
				scaleClip.scaleX = -this.MIN_DART_SKEW - ratio*( this.MAX_DART_SKEW-this.MIN_DART_SKEW );
			} //

		} //

		private function dragDart( dart:Entity, time:Number ):void {

			if ( this.dragCoords.length > this.MAX_DRAG_COORDS ) {
				// Shift off the two last drag coords.
				this.dragCoords.shift();
				this.dragCoords.shift();
			} //

			var loc:Spatial3D = dart.get( Spatial3D ) as Spatial3D;

			var dx:Number = loc._cx - this.prevX;
			var dy:Number = loc._cy - this.prevY;

			var sp:Spatial = dart.get( Spatial ) as Spatial;

			if ( dx == 0 && dy == 0 ) {

				// face center.
				/*var dtheta:Number = Math.atan2( -loc._cy, -loc._cx )*180/Math.PI - sp.rotation;
				if ( dtheta < -180 ) {
					dtheta += 360;
				} else if ( dtheta > 180 ) {
					dtheta -= 360;
				} //
				sp.rotation += 4*dtheta*time;*/

			} else {

				this.dragCoords.push( dx );
				this.dragCoords.push( dy );

				this.prevX = loc._cx;
				this.prevY = loc._cy;

				// Display/displayObject :\
				this.setDartSkew( loc, ((dart.get(Display) as Display).displayObject as MovieClip).getChildByName("scaleClip") as MovieClip );

				/*dtheta = Math.atan2( dy, dx )*180/Math.PI - sp.rotation;
				if ( dtheta < -180 ) {
					dtheta += 360;
				} else if ( dtheta > 180 ) {
					dtheta -= 360;
				} //
				//sp.rotation += 10*dtheta*time;*/

			} //

		} //

		/**
		 * Throw the dart when the drag ends.
		 */
		private function throwDart( dart:Entity ):void {

			var dx:Number = 0;
			var dy:Number = 0;

			var len:int = this.dragCoords.length;
			for( var i:int = len-1; i >= 0; i-- ) {
				dy += this.dragCoords[ i-- ];
				dx += this.dragCoords[ i ];
			} //
			this.dragCoords.length = 0;
			if ( len > 0 ) {
				dx /= len;
				dy /= len;
			}

			var d:Number = Math.sqrt( dx*dx + dy*dy );
			// clip throw speed limits.
			if ( d < this.MIN_THROW_SPEED ) {
				d = this.MIN_THROW_SPEED;
			} else if ( d > this.MAX_THROW_SPEED ) {
				dx = this.MAX_THROW_SPEED*dx/d;
				dy = this.MAX_THROW_SPEED*dy/d;
				d = this.MAX_THROW_SPEED;
			}

			//trace( "dx: " + dx + "  dy: " + dy );

			// fix these values later so the angle doesn't appear to change.
			var motion:Motion3D = new Motion3D( 40*dx, 40*dy, 40*d );
			motion.drag = 0;

			dart.add( new ConstantForce3D( 0, 2000, 0 ), ConstantForce3D );
			dart.add( motion, Motion3D );
			dart.remove( Draggable3D );

			( dart.get( Hit3D ) as Hit3D ).hitCheck = (this.BALLOON_HIT | this.WALL_HIT | this.FLOOR_HIT);

			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "whoosh_08.mp3" );

		} //

		override public function destroy():void {

			// check first if the event exists?
			//this.view3D.stage.removeEventListener( MouseEvent.MOUSE_DOWN, this.onMouseDown );

			super.destroy();

		} //

	} // class

} // package