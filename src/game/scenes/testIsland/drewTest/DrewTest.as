package game.scenes.testIsland.drewTest
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Threshold;
	import game.components.render.PlatformDepthCollider;
	import game.components.timeline.Timeline;
	import game.creators.motion.SceneObjectCreator;
	import game.data.comm.PopResponse;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.cavern1.shared.components.Magnet;
	import game.scenes.cavern1.shared.components.Magnetic;
	import game.scenes.cavern1.shared.components.MagneticData;
	import game.scenes.cavern1.shared.systems.MagnetSystem;
	import game.scenes.testIsland.drewTest.components.DynamicWater;
	import game.scenes.testIsland.drewTest.components.FloodWater;
	import game.scenes.testIsland.drewTest.components.Lightning;
	import game.scenes.testIsland.drewTest.components.PerlinNoise;
	import game.scenes.testIsland.drewTest.components.Splasher;
	import game.scenes.testIsland.drewTest.components.Tornado;
	import game.scenes.testIsland.drewTest.components.Wind;
	import game.scenes.testIsland.drewTest.systems.DynamicWaterSystem;
	import game.scenes.testIsland.drewTest.systems.FloodWaterSystem;
	import game.scenes.testIsland.drewTest.systems.LightningSystem;
	import game.scenes.testIsland.drewTest.systems.PerlinNoiseSystem;
	import game.scenes.testIsland.drewTest.systems.TornadoSystem;
	import game.scenes.testIsland.drewTest.systems.WindSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.DataUtils;
	import game.util.DisplayAlignment;
	import game.util.EntityUtils;
	import game.util.GridAlignment;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.flintparticles.common.displayObjects.Dot;
	
	public class DrewTest extends PlatformerGameScene
	{
		private var text:TextField = new TextField();
		
		public function DrewTest()
		{
			super();
			this.showHits = true;
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/testIsland/drewTest/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.shellApi.camera.camera.scaleTarget = 0.8;
			this.shellApi.camera.scale = this.shellApi.camera.camera.scaleTarget;
			
			this.addSystem(new BoundsCheckSystem());
			this.addSystem(new MagnetSystem());
			this.addSystem(new FollowTargetSystem());
			this.addSystem(new MotionTargetSystem());
			this.addSystem(new DestinationSystem());
			
			var ui:MovieClip = this._hitContainer["magnet"];
			this.overlayContainer.addChild(ui);
			ui.x = ui.width / 2;
			ui.y = this.shellApi.viewportHeight - ui.height / 2;
			var magnet:Entity = EntityUtils.createSpatialEntity(this, ui);
			TimelineUtils.convertClip(ui, this, magnet, null, false);
			var interaction:Interaction = InteractionCreator.addToEntity(magnet, [InteractionCreator.CLICK]);
			interaction.click.add(toggleMagnet);
			
			var clip:MovieClip = _hitContainer["magnetic"];
			
			var entity:Entity;// = EntityUtils.createMovingEntity(this, clip);
			
			//Circle
			entity = new SceneObjectCreator().create(clip, 0.7, null, clip.x, clip.y, null, null, null, this);
			entity.add(new Sleep());
			entity.add(new PlatformCollider());
			entity.add(new WallCollider());
			entity.add(new SceneCollider());
			entity.add(new BitmapCollider());
			entity.add(new PlatformDepthCollider());
			entity.add(new CurrentHit());
			entity.add(new MagneticData(1, 25));
			entity.add(new Magnetic(true));
			//entity.add(new MotionBounds(new Rectangle(645, 714, 168, 65)));
			//Motion(entity.get(Motion)).maxVelocity.setTo(200, 200);
			
			//Square
			clip = _hitContainer["box"];
			entity = EntityUtils.createMovingEntity(this, clip);
			//entity = new SceneObjectCreator().create(clip, 0.7, null, clip.x, clip.y, null, null, null, this);
			//SceneObjectMotion(entity.get(SceneObjectMotion)).rotateByVelocity = false;
			entity.add(new PlatformCollider());
			entity.add(new WallCollider());
			entity.add(new SceneCollider());
			entity.add(new BitmapCollider());
			entity.add(new PlatformDepthCollider());
			entity.add(new CurrentHit());
			entity.add(new MagneticData(1, 35));
			Motion(entity.get(Motion)).acceleration.setTo(0, 0);
			Motion(entity.get(Motion)).restVelocity = 0;
			entity.add(new Magnetic(false));
			
			
			var player:Entity = this.player;
			player.add(new MagneticData(0, 400));
			player.add(new Magnet(400));
			
			return;
			
			var shape:Shape;
			
			shape = new Shape();
			shape.graphics.beginFill(0, 0.2);
			shape.graphics.drawRect(0, 0, 240, 640);
			shape.graphics.endFill();
			shape.x = 0;
			shape.y = 0;
			this.overlayContainer.addChild(shape);
			
			var shapes:Array = [];
			
			for(var index:int = 0; index < 15; ++index)
			{
				shape = new Shape();
				shape.graphics.beginFill(Utils.randInRange(0x000000, 0xFFFFFF));
				shape.graphics.drawEllipse(-50, -20, 100, 40);
				shape.graphics.endFill();
				this.overlayContainer.addChild(shape);
				shapes.push(shape);
			}
			GridAlignment.distributeHorizontallyScaled(shapes, new Rectangle(0, 0, 240, 640), 2, 0, 0, DisplayAlignment.MID_X_MIN_Y, null, GridAlignment.RIGHT_AND_DOWN);
			//GridAlignment.distributeScaledAuto(shapes, new Rectangle(100, 400, 400, 400), 4, 4);
			
			//var file:String = "assets/ui/general/load_wheel.xml";
			
			//this.loadFile("http://www.poptropica.com/game/" + file, onXMLLoaded, file);
			
			//this.loadFile("version.xml", onXMLLoaded);
			
			var loader:URLLoader = new URLLoader();
			loader.load(new URLRequest("data/scenes/testIsland/drewTest/version.xml"));
			loader.addEventListener(Event.COMPLETE, fileLoaded);
			
			//Scott W. was removing unused scenes from testIsland.
			//Didn't want to lose this work. Moved packages and classes into DrewTest.
			this.setupDisasterSceneCode();
		}
		
		private function toggleMagnet(entity:Entity):void
		{
			var polarity:MagneticData = player.get(MagneticData);
			
			var timeline:Timeline = entity.get(Timeline);
			
			var currentIndex:int = timeline.currentIndex;
			
			if(currentIndex + 1 >= timeline.totalFrames)
			{
				currentIndex = 0;
			}
			else
			{
				currentIndex += 1;
			}
			timeline.gotoAndStop(currentIndex);
			trace(currentIndex);
			if(currentIndex == 0)
			{
				polarity.polarity = 0;
			}
			else if(currentIndex == 1)
			{
				polarity.polarity = -1;
			}
			else if(currentIndex == 2)
			{
				polarity.polarity = 1;
			}
		}
		
		private function onDataReceived(result:PopResponse):void
		{
			try
			{
				var data:URLVariables = result.data;
				
				if(data.hasOwnProperty("fields"))
				{
					text.text = "";
					
					var values:* = data.fields;
					for(var key:* in values)
					{
						var value:* = JSON.parse(values[key]);
						text.text += key + " " + value + "\n";
						trace(key, value);
					}
				}
				else
				{
					text.text = "No fields.";
				}
			} 
			catch(error:Error) 
			{
				text.text = "Bad data.";
			}
		}
		
		private function onVikingLoaded(islandXML:XML, bitmapData:BitmapData):void
		{
			var eventsTotal:int = 0;
			var eventsCompleted:int = 0;
			var eventsXML:XMLList = islandXML.permanentEvents.children();
			
			for each(var eventXML:XML in eventsXML)
			{
				if(DataUtils.getBoolean(eventXML.attribute("progression")))
				{
					++eventsTotal;
					
					var event:String = String(eventXML);
					if(this.shellApi.checkEvent(event, "viking"))
					{
						++eventsCompleted;
						trace("+", event);
					}
					else
					{
						trace("-", event);
					}
				}
				
			}
			
			trace(eventsCompleted, eventsTotal);
			
			setIslandProgression(bitmapData, eventsCompleted / eventsTotal);
		}
		
		/**
		 * Applies color manipulation to an island's BitmapData based on the player's progression.
		 * @param bitmapData The BitmapData of the island graphic.
		 * @param progression The player's progression on a scale of 0-1.
		 */
		private static function setIslandProgression(bitmapData:BitmapData, progression:Number, radius:int = 4, multiplier:Number = 1.8, gradient:Boolean = true):void
		{
			if(bitmapData != null)
			{
				//Don't accept progress that doesn't conform to a 0-1 scale.
				if(progression >= 0 && progression <= 1)
				{
					//The y value of the line dividing the grayscale region from the colored region.
					var divide:int = bitmapData.height * (1 - progression);
					
					//Only attempt to apply a grayscale if the island isn't fully completed.
					if(progression != 1)
					{
						var grayscale:Rectangle = bitmapData.rect;
						grayscale.bottom = divide;
						
						//Explains how to grayscale an image.
						//http://stackoverflow.com/questions/1098890/as3how-to-change-a-colored-bitmaps-bitmapdata-to-black-and-white
						var r:Number = 0.30;
						var g:Number = 0.59;
						var b:Number = 0.11;
						bitmapData.applyFilter(bitmapData, grayscale, new Point(), new ColorMatrixFilter([r, g, b, 0, 0, r, g, b, 0, 0, r, g, b, 0, 0, 0, 0, 0, 1, 0]));
					}
					
					//Only draw a progression line if the island hasn't been started or finished.
					if(progression > 0 && progression < 1)
					{
						//Draws a horizontal white line between the grayscale and colored regions of the island.
						var line:Rectangle = bitmapData.rect;
						
						if(gradient)
						{
							line.height = 1;
							for(var y:int = divide - radius; y < divide + radius; ++y)
							{
								line.y = y;
								var ratio:Number = (radius - Math.abs(divide - y)) / radius;
								var multiplierFinal:Number = Utils.convertRatio(ratio, 0, 1, 1, multiplier);
								bitmapData.colorTransform(line, new ColorTransform(multiplierFinal, multiplierFinal, multiplierFinal));
							}
						}
						else
						{
							line.top = divide - radius;
							line.bottom = divide + radius;
							bitmapData.colorTransform(line, new ColorTransform(multiplier, multiplier, multiplier));
						}
					}
				}
			}
		}
		
		private function setPixels(bmd:BitmapData, rect:Rectangle, color:uint):void
		{
			for(var y:int = rect.top; y < rect.bottom; ++y)
			{
				for(var x:int = rect.left; x < rect.right; ++x)
				{
					if((bmd.getPixel32(x, y) >> 24 & 0xFF) > 0)
					{
						bmd.setPixel32(x, y, color);
					}
				}
			}
		}
		
		private function fileLoaded(event:Event):void
		{
			var xml:XML = XML(URLLoader(event.currentTarget).data);
			trace(xml);
			var byteArray:ByteArray = new ByteArray();
			//byteArray.writeObject(xml.toXMLString());
			byteArray.writeUTFBytes(xml.toXMLString());
			/*var directory:String = File.applicationStorageDirectory.url + "assets/scenes/testIsland/drewTest/testFolder/";
			
			var file:File = new File(directory);
			file.createDirectory();
			return;*/
			var file:File = File.applicationStorageDirectory.resolvePath("data/scenes/testIsland/drewTest/testFolder/version.xml");
			//file.preventBackup = true; // 0229 - This was causing problems on build as preventBackup is undefined
			
			var outStream:FileStream = new FileStream(); 
			outStream.open(file, FileMode.WRITE); 
			outStream.writeBytes(byteArray); 
			outStream.close();
			
			var loader:URLLoader = new URLLoader();
			loader.load(new URLRequest(file.nativePath));
			loader.addEventListener(Event.COMPLETE, onXMLLoaded);
		}
		
		private function onXMLLoaded(event:Event):void
		{
			trace(URLLoader(event.currentTarget).data);
			trace(XML(URLLoader(event.currentTarget).data));
		}
		
		private function setupDisasterSceneCode():void
		{
			//this.setupParticleMovement();
			
			//this.setupTesting();
			
			//this.setupHouse();
			//this.setupWind();
			//this.setupDynamicWater();
			//this.setupFlood();
			
			this.setupPerlinNoise();
			this.setupTornado();
			//this.setupLightning();
		}
		
		
		/***********************************************************************
		 * <b>Perlin Noise Setup</b>
		 */
		private function setupPerlinNoise():void
		{
			this.addSystem(new PerlinNoiseSystem(), SystemPriorities.lowest);
			
			var dot:Dot = new Dot(5);
			dot.x = 580;
			dot.y = 650;
			this._hitContainer.addChild(dot);
			
			var entity:Entity = new Entity();
			this.addEntity(entity);
			
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			entity.add(new Display(sprite, this._hitContainer));
			entity.add(new Spatial(580, 650));
			entity.add(new Sleep(false, true));
			entity.add(new Id("perlinNoise"));
			
			var noise:PerlinNoise = new PerlinNoise(400, 400);
			for(var i:int = 0; i < noise.numOctaves; i++)
				noise.speeds.add(new Point(Utils.randNumInRange(-60, 60), Utils.randNumInRange(-60, 60)));
			entity.add(noise);
		}
		
		/***********************************************************************
		 * <b>Tornado Setup</b>
		 */
		private function setupTornado():void
		{
			this.addSystem(new TornadoSystem(), SystemPriorities.lowest);
			this.addSystem(new ThresholdSystem());
			
			var entity:Entity = new Entity();
			this.addEntity(entity);
			
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			entity.add(new Display(sprite, this._hitContainer));
			entity.add(new Spatial(580, 920));
			entity.add(new Sleep(false, true));
			entity.add(new Id("tornado"));
			entity.add(new Tornado());
			entity.add(new Tween());
			
			entity.add(new AudioRange(1000));
			var audio:Audio = new Audio();
			audio.play(SoundManager.AMBIENT_PATH + "strong_winds_01.mp3", true, SoundModifier.POSITION);
			entity.add(audio);
			
			var motion:Motion = new Motion();
			motion.acceleration = new Point(150, 0);
			motion.friction = new Point(100);
			entity.add(motion);
			
			/**
			 * Camera Target
			 */
			this.shellApi.camera.target = entity.get(Spatial);
			
			this.moveRight(entity);
		}
		
		private function moveLeft(entity:Entity):void
		{
			var tornado:Tornado = entity.get(Tornado);
			tornado.speed = 2;
			tornado.circleColor = 0x00CCFF;
			tornado.particleColors = [0x0066FF, 0x00CCFF, 0xFFFFFF];
			
			entity.get(Motion).acceleration.x = -150;
			
			var threshold:Threshold = new Threshold("x", "<=");
			threshold.threshold = 1000;
			threshold.entered.addOnce(Command.create(moveRight, entity));
			entity.add(threshold);
			
			var object:Object = { startRadius:100 };
			var tween:Tween = entity.get(Tween);
			tween.to(tornado, 2, object);
		}
		
		private function moveRight(entity:Entity):void
		{
			var tornado:Tornado = entity.get(Tornado);
			tornado.speed = 3;
			tornado.circleColor = 0x000000;
			tornado.particleColors = [0x111111, 0x333333, 0x552200, 0x003300];
			
			entity.get(Motion).acceleration.x = 150;
			
			var threshold:Threshold = new Threshold("x", ">=");
			threshold.threshold = 2000;
			threshold.entered.addOnce(Command.create(moveLeft, entity));
			entity.add(threshold);
			
			var object:Object = { startRadius:150 };
			var tween:Tween = entity.get(Tween);
			tween.to(tornado, 2, object);
		}
		
		/***********************************************************************
		 * <b>Wind Setup</b>
		 */
		private function setupWind():void
		{
			//True  -> Use Hit Container
			//False -> Use Group Container
			var boolean:Boolean = false;
			
			this.addSystem(new WindSystem(), SystemPriorities.lowest);
			
			var entity:Entity = new Entity();
			this.addEntity(entity);
			
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			if(boolean)
			{
				entity.add(new Display(sprite, this._hitContainer));
				entity.add(new Spatial(0, 0));
				entity.add(new Wind(this.sceneData.cameraLimits));
			}
			else
			{
				entity.add(new Display(sprite, this.groupContainer));
				entity.add(new Spatial(-this.shellApi.viewportWidth * 0.5, -this.shellApi.viewportHeight * 0.5));
				
				var box:Rectangle = new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight)
				
				entity.add(new Wind(box));
			}
			
			
			entity.add(new Sleep(false, true));
			entity.add(new Id("wind"));
			
			var audio:Audio = new Audio();
			//audio.play(SoundManager.AMBIENT_PATH + "strong_winds_01.mp3", true, SoundModifier.POSITION);
			entity.add(audio);
		}
		
		/***********************************************************************
		 * <b>Lightning Setup</b>
		 */
		private function setupLightning():void
		{
			//True  -> Use Hit Container
			//False -> Use Group Container
			var boolean:Boolean = false;
			
			this.addSystem(new LightningSystem(), SystemPriorities.lowest);
			
			var entity:Entity = new Entity();
			this.addEntity(entity);
			
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			if(boolean)
			{
				entity.add(new Display(sprite, this._hitContainer));
				entity.add(new Spatial(0, 0));
				entity.add(new Lightning(this.sceneData.cameraLimits));
			}
			else
			{
				entity.add(new Display(sprite, this.groupContainer));
				entity.add(new Spatial(-this.shellApi.viewportWidth * 0.5, -this.shellApi.viewportHeight * 0.5));
				
				var box:Rectangle = new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight)
				
				entity.add(new Lightning(box));
			}
			
			entity.add(new Sleep(false, true));
			entity.add(new Id("lightning"));
			entity.add(new Audio());
			
			/**
			 * Camera Target
			 */
			this.shellApi.camera.target = new Spatial(1000, 600);
		}
		
		/***********************************************************************
		 * <b>Dynamic Water Setup</b>
		 */
		private function setupDynamicWater():void
		{
			this.addSystem(new DynamicWaterSystem(), SystemPriorities.lowest);
			
			var entity:Entity = new Entity();
			this.addEntity(entity);
			
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			entity.add(new Display(sprite, this._hitContainer));
			entity.add(new Spatial(0, 0));
			entity.add(new Sleep(false, true));
			entity.add(new Id("dynamicWater"));
			
			entity.add(new DynamicWater(this.sceneData.cameraLimits, 200, 50));
			
			this.player.add(new Splasher());
		}
		
		/***********************************************************************
		 * <b>Flood Setup</b>
		 */
		private function setupFlood():void
		{
			this.addSystem(new FloodWaterSystem(), SystemPriorities.lowest);
			
			var entity:Entity = new Entity();
			this.addEntity(entity);
			
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			entity.add(new Display(sprite, this._hitContainer));
			entity.add(new Spatial(0, 0));
			entity.add(new Sleep(false, true));
			entity.add(new Id("flood"));
			entity.add(new Tween());
			
			var box:Rectangle = new Rectangle(0, 0, 1000, 1000);
			
			entity.add(new FloodWater(this.sceneData.cameraLimits, 200, 50));
		}
	}
}