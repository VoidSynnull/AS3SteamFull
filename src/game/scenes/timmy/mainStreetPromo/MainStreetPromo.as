package game.scenes.timmy.mainStreetPromo
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Npc;
	import game.components.motion.Edge;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.scene.characterDialog.DialogData;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.timmysStreet.TimmysStreet;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.hud.HudPopBrowser;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	
	public class MainStreetPromo extends TimmyScene
	{
		private var _promoTimmy:Entity;
		private var _promoTimmyMouth:Entity;
		private var _promoTotal:Entity;
		private var _promoStore:Entity;
		private var _tweenStoreIcon:Boolean 					=	false;
		private const GOT_COSTUME:String 						=	"got_costume";
		private const GOT_POSTER:String 						=	"got_poster";
		private const GOT_COLORING_POSTER:String				=	"got_coloring_poster";
		
		public function MainStreetPromo()
		{
			super();
		}
		
		override protected function addBaseSystems():void 
		{
			addSystem( new WaveMotionSystem());
			super.addBaseSystems();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/mainStreetPromo/";
			
			super.init(container);
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			setupTimmy();
			super.addCharacterDialog( container );
		}
		
		private function setupTimmy():void
		{
			var clip:MovieClip;
			var dialog:Dialog;
			var entity:Entity;
			var sceneInteraction:SceneInteraction;
			
			// TIMMY SETUP
			clip										= 	_hitContainer[ "timmy" ];
			super.convertContainer( clip.mouth, PerformanceUtils.defaultBitmapQuality );
			super.convertContainer( clip.scarf1, PerformanceUtils.defaultBitmapQuality );
			super.convertContainer( clip.scarf2, PerformanceUtils.defaultBitmapQuality );
			
			_promoTimmy									= 	EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			TimelineUtils.convertClip( clip, this, _promoTimmy, null );
			_promoTimmyMouth							= 	TimelineUtils.convertClip( clip.mouth, this, null, _promoTimmy, false );
			TimelineUtils.convertClip( clip.scarf1, this, null, _promoTimmy );
			TimelineUtils.convertClip( clip.scarf2, this, null, _promoTimmy );
			
			InteractionCreator.addToEntity( _promoTimmy, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( _promoTimmy );
			sceneInteraction					 		=	new SceneInteraction();
			sceneInteraction.reached.add( runPromoTimmyDialog );
			
			// TIMMY DIALOG
			dialog = new Dialog();
			dialog.faceSpeaker 							=	false;
			
			dialog.dialogPositionPercents = new Point( 0, .5 );				
			_promoTimmy.add( dialog ).add( new Id( "timmy" )).add( sceneInteraction )
						.add( new Edge( 50, 50, 50, 80 )).add( new Npc());
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			shellApi.loadScene( TimmysStreet, 550, 953, "right" );
//			super.loaded();
//			shellApi.eventTriggered.add( eventTriggered );
//			
//			var clip:MovieClip;
//			var dialog:Dialog;
//			var memberLink:Entity;
//			var number:int;
//			var removable:Vector.<String>;
//			var sceneInteraction:SceneInteraction;
//					
//			// TOTAL SETUP
//			clip 										= 	_hitContainer[ "total" ];
//			_promoTotal 								= 	EntityUtils.createSpatialEntity( this, clip, _hitContainer );
//			TimelineUtils.convertClip( clip, this, _promoTotal );
//						
//			// TOTAL SIGN LINK
//			clip 										=	_hitContainer[ "memberTour" ];
//			memberLink									=	EntityUtils.createSpatialEntity( this, clip, _hitContainer );
//			
//			InteractionCreator.addToEntity( memberLink, [ InteractionCreator.CLICK ]);
//			ToolTipCreator.addToEntity( memberLink );
//			sceneInteraction 							=	new SceneInteraction();
//			sceneInteraction.reached.add( clickedMembership );
//			sceneInteraction.offsetY 					=	100;
//			memberLink.add( sceneInteraction );
//			
////			clip 										=	_hitContainer[ "closed2" ];
////			DisplayUtils.moveToBack( clip );
//			_hitContainer.removeChild( _hitContainer[ "closed2" ]);
//			clip 										=	_hitContainer[ "closed3" ];
//			DisplayUtils.moveToBack( clip );
//			// REMOVE THE COLORED CLOSED SIGNES - UNTIL THE SECOND PROMO TIME
//			removable									=	new <String>[ "closed1" ]; //"closed2",
//			
//			for( number = 0; number < removable.length; number ++ )
//			{
//				_hitContainer.removeChild( _hitContainer[ removable[ number ]]);		
//			}
//			
//			// remove common room door
//	//		var door:Entity 							=	getEntityById( "doorCommon" );
//	//		removeEntity( door );
//			
//			// STORE ICON
//			clip 										=	_hitContainer[ "store" ];
//			_promoStore									=	EntityUtils.createSpatialEntity( this, clip );
//			
//			var waveMotionData:WaveMotionData			=	new WaveMotionData( "y", .3, .1 );
//			var waveMotion:WaveMotion					=	new WaveMotion();
//			waveMotion.add( waveMotionData );
//			_promoStore.add( waveMotion ).add( new Tween()); 
//			
//			Display( _promoStore.get( Display )).alpha 	=	0;
//			
//	//		sceneInteraction 							=	_promoTimmy.get( SceneInteraction );
//	//		sceneInteraction.reached.removeAll();
//	//		sceneInteraction.reached.add( findTimmyDialog );
		}
		
		private function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
//			if( event == "talk" )
//			{
//				runPromoTimmyDialog();
//			}
//			else if( event == "store_icon" )
//			{
//				_tweenStoreIcon 						=	true;
//				var tween:Tween 						=	_promoStore.get( Tween );
//				var display:Display 					=	_promoStore.get( Display );
//				tween.to( display, 1.5, { alpha : 1 });
//			}
			if( event=="store_icon2" )
			{
				_tweenStoreIcon 						=	true;
				var tween:Tween 						=	_promoStore.get( Tween );
				var display:Display 					=	_promoStore.get( Display );
				tween.to( display, 1.5, { alpha : 1 });
			}
		}
		
		private function runPromoTimmyDialog( player:Entity, timmy:Entity ):void
		{
			var timeline:Timeline 						= _promoTimmyMouth.get( Timeline );
			timeline.gotoAndPlay( 1 );
			
			var dialog:Dialog 							=	_promoTimmy.get( Dialog );
			dialog.complete.add( stopPromoTimmyDialog );
		}
		
		private function stopPromoTimmyDialog( dialogData:DialogData ):void
		{
			var timeline:Timeline = _promoTimmyMouth.get( Timeline );
			timeline.gotoAndStop( 0 );
			
			if( _tweenStoreIcon )
			{
				_tweenStoreIcon							=	false;
				
				var tween:Tween 						=	_promoStore.get( Tween );
				var display:Display 					=	_promoStore.get( Display );
				tween.to( display, 1.5, { alpha : 0 });
			}
		}
		
		// TOTAL SIGN
		private function clickedMembership( player:Entity, sign:Entity ):void
		{
			//	shellApi.track( "GetEarlyAccess_MainStreetCSSign", null, null, "TimmyFailureIsland" );
			HudPopBrowser.buyMembership(super.shellApi, "source=POP_img_GetEarlyAccess_MainStreetCSSign-pop&medium=Display&campaign=TimmyIsland");
		}
	}
}