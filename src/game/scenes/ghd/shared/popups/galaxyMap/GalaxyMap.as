package game.scenes.ghd.shared.popups.galaxyMap
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.data.ui.TransitionData;
	import game.scenes.ghd.GalacticHotDogEvents;
	import game.scenes.ghd.barren1.Barren1;
	import game.scenes.ghd.mushroom1.Mushroom1;
	import game.scenes.ghd.outerSpace.OuterSpace;
	import game.scenes.ghd.prehistoric1.Prehistoric1;
	import game.scenes.ghd.shared.PlanetGenerator;
	import game.scenes.ghd.shared.RandomBMD;
	import game.scenes.ghd.shared.StarData;
	import game.scenes.ghd.spacePort.SpacePort;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	
	public class GalaxyMap extends Popup
	{
		public const GALAXY_SEED:uint = 545267;//Do not change! That means you.
		
		public var stars:Vector.<StarData> = new Vector.<StarData>();
		public var starColors:Array = [0xFEFFBF, 0xFFCC00, 0x5EC2F2, 0xFF6600, 0x00BB00];
		public var events:GalacticHotDogEvents;
		public var zooming:Boolean = false;
		public var zoomed:Boolean = false;
		public var cellX:int;
		public var cellY:int;
		
		private var sectorDagger:Point = new Point(3, 0);
		private var sectorHumphree:Point = new Point(1, 2);
		private var sectorCosmoe:Point = new Point(2, 3);
		
		private var sectors:String = "0000000000000000000000000";
		
		//These generate the planets when they're found. The seeds are GalaxySeed + Star (x, y) + Planet (x, y)
		private var planetDagger:uint = GALAXY_SEED + 347 + 71 + 2580 + 647;
		private var planetHumphree:uint = GALAXY_SEED + 166 + 276 + 2529 + 791;
		private var planetCosmoe:uint = GALAXY_SEED + 280 + 388 + 1020 + 1304;
		
		private var planetGenerator:PlanetGenerator = new PlanetGenerator();
		private var selector:MovieClip;
		private var information:MovieClip;
		
		private var _events:GalacticHotDogEvents;
		
		public function GalaxyMap(container:DisplayObjectContainer = null)
		{
			super(container);
			_events = new GalacticHotDogEvents();
			
			this.id 				= "GalaxyMap";
			this.groupPrefix 		= "scenes/ghd/shared/popups/galaxyMap/";
			this.screenAsset 		= "galaxyMap.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{
			this.screen.content.galaxyPanel.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Bounce.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this.events = this.shellApi.islandEvents as GalacticHotDogEvents;
			
			this.setupScannedSectors();
			this.setupContent();
			this.setupFriendButtons();
			this.setupPlanetButtons();
			this.setupGalaxy();
			this.setupZoomOutButton();
			this.setupCloseButton();
			this.setupFunketownButton();
			this.setupTransmission();
			this.setupInformationBar();
			this.setupPreviousSector();
		}
		
		private function setupPreviousSector():void
		{
			if(this.shellApi.currentScene is OuterSpace)
			{
				var outerSpace:OuterSpace = this.shellApi.currentScene as OuterSpace;
				
				if(outerSpace.star)
				{
					var cellX:int = Math.floor(outerSpace.star.x / selector.width);
					var cellY:int = Math.floor(outerSpace.star.y / selector.height);
					
					this.zoomToSector(new Point(cellX, cellY));
				}
			}
		}
		
		private function setupScannedSectors():void
		{
			this.selector = this.screen.content.galaxyPanel.selector;
			
			if(this.shellApi.checkEvent(events.RECOVERED_CREW)) return;
			
			this.shellApi.getUserField(_events.SECTORS_FIELD, this.shellApi.island, setSectors, true);
		}
		
		private function setSectors(sectors:String):void
		{
			if(sectors && sectors.length == 25)
			{
				this.sectors = sectors;
			}
			
			for(var index:int = 0; index < 25; ++index)
			{
				var cellX:int = (index % 5);
				var cellY:int = Math.floor(index / 5);
				
				var sector:String = this.sectors.charAt(index);
				
				if(sector == "1")
				{
					this.colorSector(cellX, cellY, false);
				}
				else if(sector == "2")
				{
					this.colorSector(cellX, cellY, true);
				}
			}
		}
		
		private function scanSector():void
		{
			if(!this.zoomed) return;
			
			var index:int = this.cellY * 5 + this.cellX;
			
			var sector:String = this.sectors.charAt(index);
			
			if(sector == "0")
			{
				var friend:String;
				var point:Point = new Point(this.cellX, this.cellY);
				
				if(point.equals(sectorDagger))
				{
					friend = "dagger";
				}
				else if(point.equals(sectorHumphree))
				{
					friend = "humphree";
				}
				else if(point.equals(sectorCosmoe))
				{
					friend = "cosmoe";
				}
				
				var newSectors:String = this.sectors.substring(0, index);
				
				if(friend)
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "radio_static_burst_01.mp3", 1, false, [SoundModifier.EFFECTS]);
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03c.mp3", 1, false, [SoundModifier.EFFECTS]);
					
					newSectors += "2";
					this.information.gotoAndStop(4);
					
					if(!this.shellApi.checkEvent(this.events.FOUND_TRANSMISSION_ + friend))
					{
						this.shellApi.triggerEvent(this.events.FOUND_TRANSMISSION_ + friend, true);
						
						createFriendButton(friend);
						
						this.showTransmission(friend);
					}
				}
				else
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_17.mp3", 1, false, [SoundModifier.EFFECTS]);
					
					newSectors += "1";
					this.information.gotoAndStop(3);
				}
				
				newSectors += this.sectors.substring(index + 1);
				
				this.sectors = newSectors;
				this.shellApi.setUserField(_events.SECTORS_FIELD, this.sectors, this.shellApi.island, true);
				
				this.colorSector(this.cellX, this.cellY, friend);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, selectStarInfo));
			}
		}
		
		private function showTransmission(friend:String):void
		{
			var transmission:MovieClip = this.screen.content.transmission;
			transmission.visible = true;
			transmission.picture.gotoAndStop(friend);
		}
		
		private function colorSector(cellX:int, cellY:int, foundNPC:Boolean):void
		{
			var scanned:MovieClip = this.screen.content.galaxyPanel.scanned;
			
			scanned.graphics.beginFill(foundNPC ? 0x00FF00 : 0xFF0000, 0.5);
			scanned.graphics.drawRect(cellX * selector.width, cellY * selector.height, selector.width, selector.height);
			scanned.graphics.drawRect(cellX * selector.width + 2, cellY * selector.height + 2, selector.width - 4, selector.height - 4);
			scanned.graphics.endFill();
		}
		
		private function setupInformationBar():void
		{
			this.information = this.screen.content.information;
			this.information.mouseChildren = false;
			this.information.mouseEnabled = false;
			this.information.gotoAndStop(1);
		}
		
		private function setupTransmission():void
		{
			this.screen.content.transmission.visible = false;
			ButtonCreator.createButtonEntity(this.screen.content.transmission.exit, this, onTransmissionExit, null, null, null, true, true);
		}
		
		private function onTransmissionExit(entity:Entity):void
		{
			this.screen.content.transmission.visible = false;
		}
		
		private function setupFunketownButton():void
		{
			ButtonCreator.createButtonEntity(this.screen.content.home, this, onFunketownClick, null, null, null, true, true);	
		}
		
		private function onFunketownClick(entity:Entity):void
		{
			this.shellApi.loadScene(SpacePort);
		}
		
		private function setupCloseButton():void
		{
			ButtonCreator.createButtonEntity(this.screen.content.exit, this, onCloseClick, null, null, null, true, true);	
		}
		
		private function onCloseClick(entity:Entity):void
		{
			this.close();
		}
		
		private function setupZoomOutButton():void
		{
			var entity:Entity = ButtonCreator.createButtonEntity(this.screen.content.zoom, this, onZoomOutClick, null, null, null, true, true);
			entity.add(new Id("zoomButton"));
			Display(entity.get(Display)).visible = false;
		}
		
		private function onZoomOutClick(entity:Entity):void
		{
			if(this.zoomed)
			{
				this.zoomed = false;
				
				selector.visible = true;
				
				this.information.gotoAndStop(1);
				this.screen.content.transmission.visible = false;
				this.screen.content.grid.visible = true;
				
				Display(entity.get(Display)).visible = false;
				
				entity = this.getEntityById("galaxyPanel");
				
				var tween:Tween = this.getGroupEntityComponent(Tween);
				
				tween.removeTweenByName("loader");
				tween.removeTweenByName("scanner");
				tween.removeTweenByName("galaxyPanel");
				
				this.screen.content.scanner.y = 612;
				tween.to(entity.get(Spatial), 0.5, {x:52, y:32, scaleX:1, scaleY:1}, "galaxyPanel");
			}
		}
		
		private function setupContent():void
		{
			var content:MovieClip = this.screen.content;
			content.x = this.shellApi.viewportWidth / 2 - content.width / 2;
			content.y = this.shellApi.viewportHeight / 2 - content.height / 2;
		}
		
		private function setupFriendButtons():void
		{
			createFriendButton("cosmoe");
			createFriendButton("dagger");
			createFriendButton("humphree");
		}
		
		private function createFriendButton(friend:String):void
		{
			var clip:MovieClip = this.screen.content["friend_" + friend];
			if(this.shellApi.checkEvent(events.FOUND_TRANSMISSION_ + friend))
			{
				clip.gotoAndStop(friend);
				
				if(!this.shellApi.checkEvent(events.RECOVERED_ + friend))
				{
					clip.check.visible = false;
					
					var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
					entity.add(new Id(clip.name));
					var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
					interaction.click.add(onFriendClicked);
					ToolTipCreator.addToEntity(entity);
				}
				else
				{
					clip.check.visible = true;
				}
				
			}
			else
			{
				clip.check.visible = false;
				clip.gotoAndStop(4);
			}
		}
		
		private function onFriendClicked(entity:Entity):void
		{
			var friend:String = Id(entity.get(Id)).id;
			friend = friend.replace("friend_", "");
			
			if(friend == "dagger")
			{
				this.zoomToSector(sectorDagger, friend);
			}
			else if(friend == "humphree")
			{
				this.zoomToSector(sectorHumphree, friend);
			}
			else if(friend == "cosmoe")
			{
				this.zoomToSector(sectorCosmoe, friend);
			}
		}
		
		private function setupPlanetButtons():void
		{
			if(this.shellApi.checkEvent(events.FOUND_PLANET_PREHISTORIC))
			{
				createPlanetButton("Prehistoric1", this.planetCosmoe);
			}
			
			if(this.shellApi.checkEvent(events.FOUND_PLANET_BARREN))
			{
				createPlanetButton("Barren1", this.planetDagger);
			}
			
			if(this.shellApi.checkEvent(events.FOUND_PLANET_MUSHROOM))
			{
				createPlanetButton("Mushroom1", this.planetHumphree);
			}
		}
		
		private function createPlanetButton(planet:String, seed:uint):void
		{
			var clip:MovieClip = this.screen.content[planet];
			clip.mouseChildren = true;
			clip.mouseEnabled = true;
			
			var sprite:Sprite = planetGenerator.create(seed);
			sprite.x = sprite.y = 0;
			sprite.width = sprite.height = clip.width - 5;
			sprite.mouseChildren = true;
			sprite.mouseEnabled = true;
			
			clip.addChildAt(sprite, 1);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			entity.add(new Id(planet));
			var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
			interaction.click.add(onPlanetClick);
			ToolTipCreator.addToEntity(entity);
		}
		
		private function onPlanetClick(entity:Entity):void
		{
			var planet:String = Id(entity.get(Id)).id;
			
			if(planet == "Mushroom1")
			{
				this.shellApi.loadScene(Mushroom1);
			}
			else if(planet == "Barren1")
			{
				this.shellApi.loadScene(Barren1);
			}
			else if(planet == "Prehistoric1")
			{
				this.shellApi.loadScene(Prehistoric1);
			}
		}
		
		private function setupGalaxy():void
		{
			var panel:MovieClip = this.screen.content.galaxyPanel;
			var background:MovieClip = panel.background;
			var stars:MovieClip = panel.stars;
			
			var galaxy:Shape = new Shape();
			
			var seedBMD:BitmapData = new BitmapData(5, 100, false, 0);
			seedBMD.noise(GALAXY_SEED, 0, 255, 0, true);
			
			var matrix:Matrix = new Matrix();
			
			for(var i:uint = 0; i < 100; i++)
			{
				var star:StarData = new StarData();
				star.x = RandomBMD.integer(seedBMD, 0, i, 0, background.width);
				star.y = RandomBMD.integer(seedBMD, 1, i, 0, background.height);
				star.color = starColors[RandomBMD.integer(seedBMD, 2, i, 0, starColors.length - 1)];
				
				var radius:Number = RandomBMD.number(seedBMD, 3, i, 4, 7);
				
				matrix.createGradientBox(radius * 2, radius * 2, 0, -radius, -radius);
				
				var shape:Shape = new Shape();
				shape.graphics.beginGradientFill(GradientType.RADIAL, [star.color, star.color, star.color], [1, 0.4, 0], [0, 80, 255], matrix);
				shape.graphics.drawCircle(0, 0, radius);
				shape.graphics.endFill();
				shape.x = star.x;
				shape.y = star.y;
				stars.addChild(shape);
				
				this.stars.push(star);
			}
			
			var panelEntity:Entity = EntityUtils.createSpatialEntity(this, panel);
			panelEntity.add(new Id("galaxyPanel"));
			var interaction:Interaction = InteractionCreator.addToEntity(panelEntity, [InteractionCreator.CLICK]);
			interaction.click.add(this.onGalaxyPanelClick);
			
			panel.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(event:MouseEvent):void
		{
			if(!this.zoomed)
			{
				var panel:MovieClip = this.screen.content.galaxyPanel;
				
				var cellX:int = Math.floor(panel.mouseX / selector.width);
				var cellY:int = Math.floor(panel.mouseY / selector.height);
				
				if(this.cellX != cellX || this.cellY != cellY)
				{
					this.cellX = cellX;
					this.cellY = cellY;
					
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_05.mp3", 1, false, [SoundModifier.EFFECTS]);
				}
				
				selector.x = cellX * selector.width;
				selector.y = cellY * selector.height;
			}
		}
		
		private function onGalaxyPanelClick(entity:Entity):void
		{
			var display:MovieClip = Display(entity.get(Display)).displayObject;
			
			if(!this.zoomed)
			{
				var cellX:int = Math.floor(display.mouseX / selector.width);
				var cellY:int = Math.floor(display.mouseY / selector.height);
				
				this.zoomToSector(new Point(cellX, cellY));
			}
			else
			{
				for each(var star:StarData in this.stars)
				{
					var distanceSquared:Number = GeomUtils.distSquared(display.mouseX, display.mouseY, star.x, star.y);
					if(distanceSquared < 4 * 4)
					{
						trace(star.x, star.y);
						
						var outerSpace:OuterSpace = new OuterSpace();
						outerSpace.galaxySeed = GALAXY_SEED;
						outerSpace.star = star;
						outerSpace.planetCosmoe = this.planetCosmoe;
						outerSpace.planetDagger = this.planetDagger;
						outerSpace.planetHumphree = this.planetHumphree;
						this.shellApi.loadScene(outerSpace);
						
						break;
					}
				}
			}
		}
		
		private function zoomToSector(sector:Point, friend:String = null):void
		{
			this.zoomed = true;
			
			this.cellX = sector.x;
			this.cellY = sector.y;
			
			selector.visible = false;
			selector.x = this.cellX * selector.width;
			selector.y = this.cellY * selector.height;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_06.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var entity:Entity
			var tween:Tween = this.getGroupEntityComponent(Tween);
			
			var cellX:int = sector.x * -selector.width * 5;
			var cellY:int = sector.y * -selector.height * 5;
			
			this.screen.content.grid.visible = false;
			
			entity = this.getEntityById("galaxyPanel");
			tween.to(entity.get(Spatial), 0.5, {x:cellX + 52, y:cellY + 33, scaleX:5, scaleY:5, onComplete:onZoomComplete, onCompleteParams:[friend]}, "galaxyPanel");
			
			entity = this.getEntityById("zoomButton");
			Display(entity.get(Display)).visible = true;
		}
		
		private function onZoomComplete(friend:String = null):void
		{
			var index:int = this.cellY * 5 + this.cellX;
			
			var sector:String = this.sectors.charAt(index);
			
			if(!this.shellApi.checkEvent(events.RECOVERED_CREW) && sector == "0")
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "scan_01.mp3", 1, false, [SoundModifier.EFFECTS]);
				
				var tween:Tween = this.getGroupEntityComponent(Tween);
				
				var clip:MovieClip;
				
				this.information.gotoAndStop(2);
				
				clip = this.information.loader;
				clip.scaleX = 0;
				tween.to(clip, 2, {scaleX:1, ease:Linear.easeNone, onComplete:this.scanSector}, "loader");
				
				clip = this.screen.content.scanner;
				clip.y = 33;
				tween.to(clip, 2, {y:612, ease:Linear.easeNone}, "scanner");
			}
			else
			{
				if(friend)
				{
					this.showTransmission(friend);
				}
				this.information.gotoAndStop(5);
			}
		}
		
		private function selectStarInfo():void
		{
			if(this.zoomed)
			{
				this.information.gotoAndStop(5);
			}
		}
	}
}