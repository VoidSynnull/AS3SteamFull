package game.scenes.carrot.vent
{
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.creators.entity.EmitterCreator;
	import game.scene.template.PlatformerGameScene;
	import game.util.ScreenEffects;
	
	public class Vent extends PlatformerGameScene
	{
		public function Vent()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/vent/";
			//super.showHits = true;
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
			
			_screenEffects = new ScreenEffects();
			
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(shellApi.viewportWidth, shellApi.viewportHeight);
			var vignette:Sprite = new Sprite();
			vignette.graphics.beginGradientFill(GradientType.RADIAL,
				[0, 0],
				[0, 1],
				[0, 255],
				matrix);
			vignette.graphics.drawRect(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			vignette.graphics.endFill();
			vignette = createBitmapSprite(vignette);
			vignette.mouseEnabled = false;			
			
			vignette.x = -super.shellApi.viewportWidth * .5;
			vignette.y = -super.shellApi.viewportHeight * .5;
			super.groupContainer.addChild(vignette);
			
			addFans(super._hitContainer);
			
			addAllDust();
		}
		
		private function addFans(container:DisplayObjectContainer):void
		{			
			var total:Number = container.numChildren;
			var clip:DisplayObjectContainer;
			var fan:Entity;
			var motion:Motion = new Motion();
			motion.rotationAcceleration = 400;
			motion.rotationMaxVelocity = 400;
			
			for (var n:Number = total - 1; n >= 0; n--)
			{
				clip = container.getChildAt(n) as DisplayObjectContainer;
				
				if (clip != null)
				{
					if(clip.name.indexOf("fan") > -1)
					{
						fan = new Entity();
						fan.add(motion);
						fan.add(new Spatial());
						fan.add(new Sleep());
						fan.add(new Display(clip["blades"]));
						clip.mouseEnabled = false;
						clip.mouseChildren = false;
						super.addEntity(fan);
					}
				}
			}
		}
		
		private function addAllDust():void
		{
			var allDustData:Vector.<Object> = new Vector.<Object>();
			
			allDustData.push( { x : 3051, y : 857, bounds : new Rectangle(2993, 211, 120, 672) } );
			allDustData.push( { x : 2036, y : 1704, bounds : new Rectangle(1982, 886, 120, 849) } );
			allDustData.push( { x : 2547, y : 1704, bounds : new Rectangle(2486, 886, 120, 849) } );
			allDustData.push( { x : 686, y : 1704, bounds : new Rectangle(626, 1064, 120, 669) } );
			allDustData.push( { x : 1026, y : 1704, bounds : new Rectangle(970, 886, 120, 849) } );
			allDustData.push( { x : 3893, y : 1704, bounds : new Rectangle(3838, 886, 120, 849) } );
			allDustData.push( { x : 4405, y : 1704, bounds : new Rectangle(4350, 886, 120, 849) } );
			allDustData.push( { x : 3557, y : 1196, bounds : new Rectangle(3494, 886, 120, 334) } );
			allDustData.push( { x : 4900, y : 2043, bounds : new Rectangle(4837, 1732, 120, 338) } );
			allDustData.push( { x : 4062, y : 2548, bounds : new Rectangle(4011, 2081, 120, 497) } );
			allDustData.push( { x : 2372, y : 2039, bounds : new Rectangle(2316, 1742, 120, 329) } );
			allDustData.push( { x : 345, y : 2043, bounds : new Rectangle(290, 1061, 120, 1010) } );
			allDustData.push( { x : 1190, y : 2552, bounds : new Rectangle(1135, 2074, 120, 505) } );
			
			var n:uint;
			for(n = 0; n < allDustData.length; n++)
			{
				addDust(allDustData[n]);
			}
		}
		
		private function addDust(dustData:Object):void
		{
			var dust:VentDust = new VentDust();
			var dustX:Number = dustData.bounds.x - 100;
			var dustY:Number = dustData.bounds.y - 160;
			
			dust.init(new Rectangle(dustX, dustY, dustX + 200, dustData.y + 10));
			
			var entity:Entity = EmitterCreator.create(this, super._hitContainer, dust);
			entity.get(Spatial).x = dustData.x;
			entity.get(Spatial).y = dustData.y;
			
			var sleep:Sleep = new Sleep();
			sleep.zone = dustData.bounds;
			entity.add(sleep);
		}
		
		private var _screenEffects:ScreenEffects;
	}
}