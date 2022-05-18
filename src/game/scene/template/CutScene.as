package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.RenderSystem;
	import engine.systems.TweenSystem;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.character.Skin;
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.data.animation.Animation;
	import game.data.character.CharacterData;
	import game.data.character.CharacterSceneData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.NpcParser;
	import game.data.game.GameEvent;
	import game.data.scene.SceneParser;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.EdgeSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class CutScene extends Scene
	{
		protected var _screen:MovieClip;
		private var _completeEvent:String = null;
		private var _player:Entity = null;
		protected var _sceneEntity:Entity;
		private var _border:Entity;
		private var _displayResolution:Point;
		private var _playerContainer:DisplayObjectContainer;
		private var _hasNpcs:Boolean = false;
		protected var _sceneAudio:Audio;
		private var _scale:Number;
		
		public var CUT_SCENE_RESOLUTION:Point = new Point(960, 640);
		
		public var audioGroup:AudioGroup;
		
		public function get player():Entity { return(_player); }
		public function get border():Entity { return(_border); }
		public function get sceneEntity():Entity { return(_sceneEntity); }
		public function get screen():MovieClip { return(_screen); }
		public function get resolution():Point { return(_displayResolution); }
		public function get completeEvent():String { return(_completeEvent); }
		public function get sceneAudio():Audio { return(_sceneAudio); }
		public function get scale():Number {return _scale;}
		
		public function CutScene()
		{
			super();
		}
		
		public function configData(prefix:String, event:String = null):void
		{
			groupPrefix = prefix;
			_completeEvent = event;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.init(container);
			loadSceneConfiguration();
		}
		
		private function loadSceneConfiguration():void
		{
			super.shellApi.fileLoadComplete.addOnce(loadData);
			super.loadFiles([GameScene.SCENE_FILE_NAME]);
		}
		
		private function loadData():void
		{
			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);
			super.sceneData = parser.parse(sceneXml);
			
			if (  super.sceneData.startPosition )
			{
				super.shellApi.profileManager.active.lastX = super.sceneData.startPosition.x;
				super.shellApi.profileManager.active.lastY = super.sceneData.startPosition.y;
				super.shellApi.profileManager.active.lastDirection = super.sceneData.startDirection;
			}
			
			if ( super.sceneData.data.length > 0 )
			{
				super.shellApi.fileLoadComplete.addOnce(loadSceneAssets);
				super.loadFiles(super.sceneData.data);
			}
			else
			{
				loadSceneAssets();
			}
		}
		
		/**
		 * Load assets specified by scene data
		 */
		private function loadSceneAssets():void
		{
			super.shellApi.fileLoadComplete.addOnce(sceneAssetsLoaded);	
			super.loadFiles(super.sceneData.assets);
		}
		
		protected function sceneAssetsLoaded():void
		{
			_screen = super.getAsset(sceneData.assets[0],true) as MovieClip;
			groupContainer.addChild(_screen);
			
			addSystems();
			
			if(super.getData(GameScene.SOUNDS_FILE_NAME) != null)
			{
				audioGroup = new AudioGroup();
				audioGroup.setupGroup(this, super.getData(GameScene.SOUNDS_FILE_NAME));
			}
			
			if(getData(GameScene.DIALOG_FILE_NAME) != null)
			{
				var dialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
				dialogGroup.setupGroup(this, getData(GameScene.DIALOG_FILE_NAME),_screen);
			}
			
			/// NOTE :: Convert before adding characters, so that charaters don't get converted twice
			_sceneEntity = convertScreen();
			// we require a 'scene' level entity to run audio trough
			if(_sceneEntity == null)
			{
				_sceneEntity = EntityUtils.createSpatialEntity(this, _screen, super.container);
			}
			else
			{
				_sceneEntity.add(new Spatial(_screen.x,_screen.y)).add(new Display(_screen, super.container));
			}
			_sceneEntity.add( new Id( "cutscene_screen") );
			
			loadCharacters();
		}
		
		protected function convertScreen():Entity
		{
			/// NOTE :: Convert before adding characters, so that charaters don't get converted twice
			return TimelineUtils.convertAllClips( _screen, null, this, false );	// TODO :: this is reconverting the character within it...
		}
		
		/**
		 * Create characters (if specified)
		 */
		protected function loadCharacters():void
		{
			var allCharSceneData:Dictionary;
			
			var npcsXml:XML = super.getData("npcs.xml");
			if( npcsXml != null )
			{
				var npcParser:NpcParser = new NpcParser();
				allCharSceneData = npcParser.parse(npcsXml);	// TODO :: may want to force to type dummy
			}
			
			if( super.sceneData.startPosition != null )
			{
				if( allCharSceneData == null ) 	{ allCharSceneData = new Dictionary(); }
				
				var playerCharData:CharacterData 	= new CharacterData();
				playerCharData.id					= CharacterCreator.TYPE_PLAYER;
				playerCharData.type					= CharacterCreator.TYPE_DUMMY;
				playerCharData.variant				= CharacterCreator.VARIANT_HUMAN;
				playerCharData.dynamicParts 		= true;
				playerCharData.position.x 			= super.sceneData.startPosition.x;
				playerCharData.position.y 			= super.sceneData.startPosition.y;
				playerCharData.direction 			= super.sceneData.startDirection;
				playerCharData.event 				= GameEvent.DEFAULT;
				
				// apply look
				if( shellApi.profileManager.active.look )
				{
					var lookConverter:LookConverter = new LookConverter();
					var look:LookData = lookConverter.lookDataFromPlayerLook( shellApi.profileManager.active.look );
					playerCharData.look = look;
				}
				else
				{
					playerCharData.look = new LookData();
				}
				
				var playerSceneData:CharacterSceneData = new CharacterSceneData( playerCharData.id );
				playerSceneData.addCharData( playerCharData );
				allCharSceneData[playerCharData.id] = playerSceneData;
			}
			
			var charGroup:CharacterGroup = new CharacterGroup();
			if( allCharSceneData != null )
			{
				_hasNpcs = true;
				charGroup.setupGroup(this, _screen, null, loaded);
				var charEntity:Entity;
				for each( var charSceneData:CharacterSceneData in allCharSceneData )
				{
					var skin:Skin = new Skin();
					skin.allowSpecialAbilities = false;
					charSceneData.setType( CharacterCreator.TYPE_DUMMY );
					charEntity = charGroup.characterCreator.createFromCharSceneData(this, charSceneData, container); 
					charEntity.add(skin);
					charGroup.addLoadCheck( charEntity );
					
					if( charSceneData.charId == CharacterCreator.TYPE_PLAYER )
					{
						super.shellApi.player = charEntity;
					}
				}
			}
			else
			{
				charGroup.setupGroup(this, container);
				loaded();
			}
		}
		
		protected function addSystems():void
		{
			addSystem(new TweenSystem());
			addSystem(new InteractionSystem());
			addSystem(new TimelineControlSystem());
			addSystem(new TimelineClipSystem());
			addSystem(new RenderSystem());
			addSystem(new FollowTargetSystem());
			addSystem(new EdgeSystem());
		}
		
		override public function loaded():void
		{
			audioGroup.addAudioToEntity(_sceneEntity);
			_sceneAudio = _sceneEntity.get(Audio);

			//setUpResolution();
			_scale = DisplayUtils.fitDisplayToScreen(this, container,CUT_SCENE_RESOLUTION);
			
			if(PlatformUtils.isMobileOS)
			{
				convertContainer(screen, PerformanceUtils.defaultBitmapQuality);
			}
			
			_player = shellApi.player;
			
			SceneUtil.lockInput( this );
			
			setTimelineHandler();
			
			if( _hasNpcs )
			{
				setUpCharacters();
			}
			else
			{
				start();
			}
		}
		
		/**
		 * For override
		 */
		public function setUpCharacters():void
		{
			start();
		}
		
		/**
		 * Default method for checking standard cutscene timeline.
		 * May want to update timeline in other way, if so override this method.
		 */
		protected function setTimelineHandler():void
		{
			var timeline:Timeline = _sceneEntity.get(Timeline);
			if(timeline != null)
			{
				timeline.handleLabel(Animation.LABEL_ENDING, end);
			}
		}
		
		
		/**
		 * Method to start standard cutscene.
		 * If cutscene needs to start in a non-standard way override this method. 
		 * @param args
		 */
		public function start(...args):void
		{
			childrenPlay(_sceneEntity);
			super.groupReady();
		}
		
		/**
		 * Sets all Timelines within given Entity to play. 
		 * Recurses through children Entities setting their Timelines to play
		 * @param entity
		 */
		protected function childrenPlay(entity:Entity):void
		{
			if( entity.has(Id) ) { trace( " CutScene :: childrenPlay : id : " + entity.get(Id).id ); }
			
			var timeline:Timeline = entity.get(Timeline);
			if(timeline != null)
			{
				timeline.labelReached.add( onLabelReached );
				timeline.play();
			}
			
			var children:Children = entity.get(Children);
			if(children != null)
			{
				for (var i:int = 0; i < children.children.length; i ++)
				{
					childrenPlay(children.children[i]);
				}
			}
		}

		public function setEntityContainer(entiy:Entity, container:DisplayObjectContainer, newX:Number = NaN, newY:Number = NaN, findLocalPosition:Boolean = false):void
		{
			var display:Display = entiy.get(Display);
			var dialog:Dialog = entiy.get(Dialog);
			//if(dialog != null)
			//	dialog.container = container;
			
			if(findLocalPosition)
			{
				var currentPosition:Point = DisplayUtils.localToLocalPoint(new Point(), display.container, container);
				
				if(isNaN(newX))
					newX = currentPosition.x;
				else
					newX += currentPosition.x;
				
				if(isNaN(newY))
					newY = currentPosition.y;
				else
					newY += currentPosition.y;
			}
			
			display.setContainer(container);
			
			var spatial:Spatial = entiy.get(Spatial);
			if(!isNaN(newX))
				spatial.x = newX;
			if(!isNaN(newY))
				spatial.y = newY;
		}
		
		/**
		 * Label handler for standard cutscene timeline, for override
		 * This handler is setup by default setTimelineHandler method.
		 * @param label
		 */
		public function onLabelReached( label:String ):void
		{
			
		}
		
		public function end():void
		{
			var sceneTimeline:Timeline = _sceneEntity.get(Timeline);
			if(sceneTimeline != null)
				sceneTimeline.gotoAndStop(sceneTimeline.currentIndex);
			if(completeEvent != null)
				shellApi.triggerEvent( completeEvent, true );
		}
	}
}