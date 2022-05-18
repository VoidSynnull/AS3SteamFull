package game.scenes.virusHunter.joesCondo.creators {

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.motion.Edge;
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Zone;
	import game.creators.ui.ToolTipCreator;
	import game.data.scene.labels.LabelData;
	import game.data.ui.ToolTipType;
	import game.scenes.virusHunter.heart.components.AngleHit;
	import game.scenes.virusHunter.joesCondo.components.ActionClick;
	import game.systems.actionChain.ActionCommand;
	import game.util.EntityUtils;
	
	// Create some basic clip types that frequently appear in scenes.
	public class ClipCreator {

		//public var sceneContainer:DisplayObjectContainer;			// Most likely this is hitContainer.

		// We can't get a handle on the engine directly, so add entities to this.
		private var group:Group;

		public function ClipCreator( engineAdder:Group ) {

			//sceneContainer = container;

			this.group = engineAdder;

		} //

		public function createZoneEntity( clip:DisplayObjectContainer,
			enterZoneFunc:Function=null, inZoneFunc:Function=null, leaveZoneFunc:Function=null ):Entity {

			var z:Zone = new Zone();

			var d:Display = new Display( clip );
			d.alpha = 0;

			var e:Entity = new Entity()
				.add( new Spatial( clip.x, clip.y ) )
				.add( z )
				.add( new Id( clip.name ) )
				.add( new Sleep() )
				.add( d );

			// need to add zone entity before setting zone signals.
			group.addEntity( e );

			if ( enterZoneFunc != null ) {
				z.entered.add( enterZoneFunc );
			}
			if ( inZoneFunc != null ) {
				z.inside.add( inZoneFunc );
			}
			if ( leaveZoneFunc != null ) {
				z.exitted.add( leaveZoneFunc );
			}

			return e;

		} //

		static public function makeAngleHit( angle:Number, height:Number, thickness:Number ):AngleHit {

			var angleHit:AngleHit = new AngleHit();
			angleHit.thickness = thickness/2;
			angleHit.height = height/2;

			angleHit.rebound = 1;

			angleHit.useSpatialAngle = false;
			angleHit.cos = Math.cos( angle*Math.PI/180 );
			angleHit.sin = Math.sin( angle*Math.PI/180 );

			return angleHit;

		} //

		/**
		 * rebound - the wall rebound, from 0 to 1 ( or more for bounce )
		 * widthPct - percentage applied to wall thickness - since some movieclips might extend
		 * 	further than you want them hittesting.
		 */
		static public function addAngleHit( e:Entity, rebound:Number=1, widthPct:Number=1 ):void {

			var clip:MovieClip = ( e.get( Display ) as Display ).displayObject as MovieClip;
			var spatial:Spatial = ( e.get( Spatial ) as Spatial );

			spatial.rotation = clip.rotation;

			clip.rotation = 0;

			var angleHit:AngleHit = new AngleHit();
			angleHit.thickness = widthPct*clip.height/2;
			angleHit.height = clip.width/2;

			angleHit.rebound = rebound;

			clip.rotation = spatial.rotation;

			if ( e.get( Sleep ) == null ) {
				e.add( new Sleep(), Sleep );
			} //

			e.add( angleHit, AngleHit );

		} //

		public function createAngleHit( clip:DisplayObjectContainer ):Entity {

			var angleHit:AngleHit = new AngleHit();

			var spatial:Spatial = new Spatial( clip.x, clip.y );
			spatial.height = clip.height;
			spatial.width = clip.width;
			spatial.rotation = clip.rotation;

			clip.rotation = 0;
			angleHit.thickness = clip.height/2;
			angleHit.height = clip.width/2;

			//clip.rotation = spatial.rotation;
			clip.parent.removeChild( clip );

			var e:Entity = new Entity()
				.add( new Id( clip.name ) )
				.add( angleHit, AngleHit )
				.add( spatial, Spatial )
				.add( new Sleep(), Sleep );

			group.addEntity( e );

			return e;

		} //

		public function createSpatialDisplay( clip:DisplayObjectContainer ):Entity {

			var d:Display = new Display( clip );
			d.alpha = clip.alpha;

			var e:Entity = new Entity()
				.add( new Spatial() )
				.add( new Id( clip.name ) )
				.add( d );

			group.addEntity( e );

			return e;

		} //

		public function createActionClick( clip:DisplayObjectContainer, action:ActionCommand, finalCallback:Function=null,
			makeClickArrow:Boolean=true ):Entity {

			var d:Display = new Display( clip );
			d.alpha = clip.alpha;

			var e:Entity = new Entity()
				.add( new Spatial() )
				.add( new Id( clip.name ) )
				.add( d )
				.add( new ActionClick( group, action, null, finalCallback ) );

			if ( makeClickArrow ) {

				var tip:Entity = ToolTipCreator.create( ToolTipType.CLICK, clip.x, clip.y );
				EntityUtils.addParentChild( tip, e );
				this.group.addEntity( tip );

			} //

			group.addEntity( e );

			return e;

		} //

		public function createClickable( clip:DisplayObjectContainer, clickFunc:Function=null, rollOverFunc:Function=null, rollOutFunc:Function=null ):Entity {

			var d:Display = new Display( clip );
			d.interactive = true;
			d.alpha = clip.alpha;

			var e:Entity = new Entity()
				.add( d )
				.add( new Id( clip.name ) )
				.add( new Spatial( clip.x, clip.y ) );

			var list:Array = new Array();
			if ( clickFunc ) {
				list.push( InteractionCreator.CLICK );
			}
			if ( rollOverFunc ) {
				list.push( InteractionCreator.OVER );
			}
			if ( rollOutFunc ) {
				list.push( InteractionCreator.OUT );
			}

			var interaction:Interaction = InteractionCreator.addToEntity( e, list, clip );

			group.addEntity( e );

			if ( clickFunc ) {
				interaction.click.add( clickFunc );
			}
			if ( rollOverFunc ) {
				interaction.over.add( rollOverFunc );
			}
			if ( rollOutFunc ) {
				interaction.out.add( rollOutFunc );
			}

			return e;

		} // createClickable()

		public function createSceneInteractor( clip:DisplayObjectContainer, arriveFunc:Function ):Entity {

			var d:Display = new Display();
			d.alpha = clip.alpha;

			var e:Entity = new Entity()
				.add( d )
				.add( new Id( clip.name ) )
				.add( new Spatial( clip.x, clip.y ) );

			InteractionCreator.addToEntity( e, [InteractionCreator.CLICK], clip );

			group.addEntity( e );

			var s:SceneInteraction = new SceneInteraction();
			s.offsetX = 30;			// the default offsetX is a little silly.

			e.add( s );

			s.reached.add( arriveFunc );

			return e;

		} //

	} // End ClipCreator
	
} // End package