// Used by:
// Card 2877 using facial limited_specs

package game.data.specialAbility.character
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.specialAbility.SpecialAbilityControl;
	import game.data.PlayerLocation;
	import game.data.animation.Animation;
	import game.data.profile.ProfileData;
	import game.data.specialAbility.SpecialAbility;
	import game.managers.ScreenManager;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.proxy.Connection;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.GameScene;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.util.ClassUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	/**
	 * go to random island
	 * 
	 * Required params:
	 * swfPath				String		Path to swf file
	 */
	public dynamic class IslandTransport extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init( node );
			_node = node;
			
			/*
			// load island list
			var request:URLRequest = new URLRequest("https://www.poptropica.com/framework/data/config.xml");
			var urlLoader:URLLoader = new URLLoader();
			
			// add listeners
			urlLoader.addEventListener(Event.COMPLETE, gotXML );
			
			// get data
			request.method = URLRequestMethod.GET;
			urlLoader.load(request);*/
			
			var count:Number = 0;
			var list:Array = shellApi.islandManager.gameData.islands;
			while (true) {
				var isValid:Boolean = false;
				count++;
				var island:String = list[ Math.floor(Math.random() * list.length)];
				var name:String = ProxyUtils.AS3IslandNameFromAS2IslandName(island);
				var invalidIslands:Array = ["timmy","hub","americangirl","map","clubhouse","start","tutorial",
					"photoboothisland","zomberry2"];
				isValid = invalidIslands.indexOf(name) == -1;
				if (isValid) {
					// check if visited or count reaches length
					var location:PlayerLocation = shellApi.profileManager.active.lastScene[name];
					if ((location == null) || count > list.length) {
						trace("IslandTransport: choice " + name);
						if(location != null) {
							scene = location.scene;
							x = location.locX;
							y = location.locY;
							direction = location.direction;
							_gotData = true;
						} else {
							shellApi.loadFile(shellApi.dataPrefix + "scenes/" + name + "/island.xml", Command.create(islandXMLLoaded, [name]));
						}
						return;
					} else {
						trace("IslandTransport: visited " + name);
					}
				}
			}
		}
		/*
		private function gotXML(e:Event):void
		{
			// note: xml file will fail to load if XML is malformed
			if ((e.target.data == null) || (e.target.data == ""))
			{
				trace("IslandTransport: gotXML failed. Check for malformed xml or missing file");
			}
			else
			{
				var xml:XML = XML(e.target.data);
				trace("IslandTransport: gotConfigXML");
				var list:XMLList = xml.child("islands").elements("island");
				var length:int = list.length();
				var count:uint = 0;
				// get random island
				while(true)
				{
					count++;
					var island:XML = list[Math.floor(Math.random() * length)];
					var name:String = ProxyUtils.AS3IslandNameFromAS2IslandName(island.child("name"));
					if ((name != "hub") && (name != "home") && (name != "party") && (name != "lands") && (name != "ftue") && (name != "haunted") && (name != "tutorial"))
					{
						var isValid:Boolean = false;
						// if AS2 island
						if (ProxyUtils.AS2_ISLANDS.indexOf(name.toLowerCase()) != -1)
						{
							isValid = false;
						}
						// if mobile
						else if (AppConfig.mobile)
						{
							if (island.child("mobile") == "true")
							{
								isValid = true;
							}
						}
						else
						{
							// if not mobile
							// if AS3 island (editor) or in browser (all islands)
							if ((island.child("islandMain") == "GlobalAS3Embassy") || (PlatformUtils.inBrowser))
							{
								isValid = true;
							}
						}
						if (isValid)
						{
							// check if visited or count reaches length
							if ((super.shellApi.profileManager.active.lastScene[name] == null) || (count >= length))
							{
								trace("IslandTransport: choice " + name);
								super.shellApi.loadFile(super.shellApi.dataPrefix + "scenes/" + name + "/island.xml", Command.create(islandXMLLoaded, name));
								return;
							}
							else
							{
								trace("IslandTransport: visited " + name);
							}							
						}
					}
				}
			}
		}
		*/
		private function islandXMLLoaded(xml:XML, name:String):void
		{
			// if xml not loaded then try another island file on mobile
			// not all islands are available on mobile
			if((!xml) || (xml == null))
			{
				return;			
			}
			
			trace("IslandTransport: gotIslandXML for " + name);			
			_gotData = true;
			
			island 				= String(xml.island);
			var firstScene:XML 	= XML(xml.firstScene);
			scene 				= String(firstScene.scene);
			x 					= Number(firstScene.x);
			y 					= Number(firstScene.y);
			direction 			= String(firstScene.direction);
			
			//SpecialAbilityControlSystem(shellApi.getManager(SpecialAbilityControlSystem)).addActionButton( shellApi.player.get( SpecialAbilityControl ), this.data );
		}
		
		private function loadSceneAS3OrAS2(island:String, scene:String, x:Number, y:Number, direction:String):void
		{
			//Go to AS3 (AS2 code removed)
			if (scene.indexOf(".") > -1)
			{
				var sceneClass:Class = ClassUtils.getClassByName(scene);
				super.shellApi.loadScene(sceneClass, x, y, direction, 0, 0);
			}
		}
		
		private function preVisit(islandName:String, sceneName:String, playerX:Number, playerY:Number, playerDirection:String):void
		{
			islandName = islandName.charAt(0).toUpperCase() + islandName.substring(1);
			var profile:ProfileData = super.shellApi.profileManager.active;
			if (profile.isGuest) {
				return;
			}
			var postVars:URLVariables = new URLVariables();
			postVars.login		= profile.login;
			postVars.pass_hash	= profile.pass_hash;
			postVars.dbid		= profile.dbid;
			postVars.island		= islandName;
			postVars.lastRoom	= sceneName;
			postVars.lastx		= playerX;
			postVars.lasty		= playerY;

			// get data
			var connection:Connection = new Connection();
			connection.connect(super.shellApi.siteProxy.secureHost + "/visit_scene.php", postVars, URLRequestMethod.POST);
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if not suppressed and not active
			if ((_gotData) && (!super.data.isActive))
			{
				SceneUtil.lockInput(super.group, true);
				if (_swfPath)
					loadPopup();
				else
					loadSceneAS3OrAS2(island, scene, x, y, direction);
			}
		}
		
		/**
		 * load popup 
		 */
		protected function loadPopup():void
		{
			var scene:GameScene = GameScene(super.shellApi.sceneManager.currentScene);			
			_container = scene.overlayContainer;			
			super.loadAsset(_swfPath, loadPopupComplete);		
		}
		
		/**
		 * when popup swf completes loading 
		 * @param clip
		 */
		protected function loadPopupComplete(clip:MovieClip):void
		{
			// return if no clip
			if (clip == null)
				return;
			
			// remember clip
			_popupClip = clip;
			
			// disable interaction
			clip.mouseChildren = clip.mouseEnabled = false;
			
			// Add the movieClip to scene
			_container.addChild(clip);
			
			// Create the new entity and set the display and spatial
			_popupClipEntity = new Entity();
			_popupClipEntity.add(new Display(clip, _container));
			
			// target proportions for device
			var targetProportions:Number = super.shellApi.viewportWidth/super.shellApi.viewportHeight;
			var destProportions:Number = ScreenManager.GAME_WIDTH/ScreenManager.GAME_HEIGHT;
			// if narrower, then fit to width and center vertically
			if (destProportions <= targetProportions)
			{
				var scale:Number = super.shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
			}
			else
			{
				// else fit to height and center horizontally
				scale = super.shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;
			}
			var x:Number = super.shellApi.viewportWidth / 2 - ScreenManager.GAME_WIDTH * scale / 2;
			var y:Number = super.shellApi.viewportHeight / 2 - ScreenManager.GAME_HEIGHT * scale/ 2;
			var clipSpatial:Spatial = new Spatial(x, y);
			clipSpatial.scaleX = clipSpatial.scaleY = scale;
			
			_popupClipEntity.add(clipSpatial);
			
			// add to scene
			super.group.addEntity(_popupClipEntity);
			
			// this converts the content clip for AS3
			_timeline = TimelineUtils.convertClip(clip.content, super.group);
			TimelineUtils.onLabel( _timeline, Animation.LABEL_ENDING, endPopupAnim );
		}
		
		/**
		 * When popup animation reaches end 
		 */
		protected function endPopupAnim():void
		{
			if (_popupClip)
			{
				// remove popup
				removePopup();
			}
			loadSceneAS3OrAS2(island, scene, x, y, direction);
		}
		
		/**
		 * Remove popup 
		 */
		private function removePopup():void
		{
			// remove popup
			_container.removeChild(_popupClip);
			super.group.removeEntity(_popupClipEntity);
			_popupClip = null;
			_popupClipEntity = null;
		}
		
		/**
		 * deactivate (end animation if running) 
		 * @param node
		 */
		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			// remove popup if exists
			if (_popupClip)
				removePopup();
		}		
		
		public var _swfPath:String;
		
		private var _gotData:Boolean = false;
		protected var _container:DisplayObjectContainer;		
		protected var _popupClipEntity:Entity;
		protected var _popupClip:MovieClip;
		protected var _timeline:Entity;
		
		private var island:String;
		private var scene:String;
		private var x:Number;
		private var y:Number;
		private var direction:String;
		private var _node:SpecialAbilityNode;		
	}
}