package game.scenes.examples.smartFoxHelloWorld
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.SFSUser;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	import com.smartfoxserver.v2.requests.LoginRequest;
	import com.smartfoxserver.v2.requests.PingPongRequest;
	
	import flash.display.DisplayObjectContainer;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	
	import game.creators.ui.ButtonCreator;
	import game.data.scene.SceneParser;
	import game.scene.template.CameraGroup;
	import game.scene.template.GameScene;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	
	public class SmartFoxHelloWorld extends Scene
	{
		public function SmartFoxHelloWorld()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{	
			super.groupPrefix = "scenes/examples/smartFoxHelloWorld/";
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loadAssets);
			super.loadFiles([GameScene.SCENE_FILE_NAME,GameScene.SOUNDS_FILE_NAME]);
		}
		
		protected function loadAssets():void
		{
			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);
			
			super.sceneData = parser.parse(sceneXml);			
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(super.sceneData.assets);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			addBaseSystems();
			
			var cameraGroup:CameraGroup = new CameraGroup();
			
			cameraGroup.setupScene(this, 1);
			
			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = Display(super.getEntityById("interactive").get(Display)).displayObject;
			
			// ----------- 
			
			setupLog();
			
			log("Scene loaded.");
			setupSmartFox(); 
			setupButtons();
		}
		
		private function setupButtons():void
		{
			ButtonCreator.createButtonEntity(_hitContainer["buttonHello"], this, onButton);
			ButtonCreator.createButtonEntity(_hitContainer["buttonAdd"], this, onButton);
			//ButtonCreator.createButtonEntity(_hitContainer["buttonPing"], this, onButton);
		}
		
		private function onButton(button:Entity):void{
			switch(Id(button.get(Id)).id){
				case "buttonHello":
					// send a simple command to the server and get a response
					_smartFox.send(new ExtensionRequest("sayHello"));
					break;
				case "buttonAdd":
					// send 2 random numbers to the server and get the sum back.
					var sfsObject:ISFSObject = new SFSObject();
					sfsObject.putInt("n1",Math.round(Math.random()*100));
					sfsObject.putInt("n2",Math.round(Math.random()*100));
					
					_smartFox.send(new ExtensionRequest("addNumbers", sfsObject));
					break;
				case "buttonPing":
					// ping the server
					_smartFox.send(new PingPongRequest());
					break;
			}
		}
		
		private function setupSmartFox():void{
			_smartFox = new SmartFox();
			_smartFox.addEventListener(SFSEvent.CONNECTION, onSFSConnect);
			_smartFox.addEventListener(SFSEvent.LOGIN, onSFSLogin);
			_smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onSFSExtension);
			//_smartFox.addEventListener(SFSEvent.PING_PONG, onPingPong);
			
			_smartFox.connect(SFS_ADDRESS,SFS_PORT);// local SFS instance
			log("Connecting to smartfox at: "+SFS_ADDRESS+" on port: "+SFS_PORT);
		}
		
		
		protected function onSFSConnect(event:SFSEvent):void
		{
			if(event.params.success){
				log("SmartFox: Successfully connected.");
				//login as a user in smartfox
				_smartFox.send(new LoginRequest("","","HelloWorld"));  // login as a guest user into the "HelloWorld" zone
			} else {
				log("Cannot connect to Smartfox at: "+SFS_ADDRESS+":"+SFS_PORT);
			}
		}
		
		protected function onSFSLogin(event:SFSEvent):void
		{
			var user:SFSUser = event.params.user;
			log("SmartFox: Logged into SFS as "+user.name+".");
		}
		
		protected function onSFSExtension(event:SFSEvent):void
		{
			switch(event.params.cmd){
				case "sayHello":
					log("SmartFox: "+ISFSObject(event.params.params).getUtfString("response"));
					break;
				case "addNumbers":
					log("SmartFox: "+ISFSObject(event.params.params).getUtfString("response"));
					break;
				default:
					log("SmartFox: "+event.params.cmd);
					break;
			}
		}
		
		protected function onPingPong(event:SFSEvent):void
		{
			log("Smartfox: Pinging at: "+event.params.lagValue);
		}
		
		
		private function setupLog():void
		{
			// setup visual console log
			_logTextField = new TextField();
			_logTextField.wordWrap = true;
			_logTextField.border = true;
			_logTextField.defaultTextFormat = new TextFormat("_typewriter", 16, 0xffffff);
			_logTextField.width = 960
			_logTextField.height = 160;
			_logTextField.y = 640 - 160;
			_hitContainer.addChild(_logTextField);
			
			_logTextField.mouseEnabled = false;
		}
		
		private function log($message:String):void{
			if(_logTextField){
				_logTextField.appendText("\n" + $message);
				_logTextField.scrollV = _logTextField.maxScrollV;
			}
		}
		
		private function addBaseSystems():void{
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			super.addSystem(new MotionSystem(), SystemPriorities.move);
			super.addSystem(new TimelineControlSystem());
			super.addSystem(new TimelineClipSystem());
		}
		
		private const SFS_ADDRESS:String = "proof.funbrain.com"; // funbrain dev server
		//private const SFS_ADDRESS:String = "127.0.0.1"; // local
		private const SFS_PORT:int = 9933;
		
		private var _hitContainer:DisplayObjectContainer;
		private var _logTextField:TextField;
		
		private var _smartFox:SmartFox;
	}
}