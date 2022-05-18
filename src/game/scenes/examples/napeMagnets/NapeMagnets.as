package game.scenes.examples.napeMagnets
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.input.Input;
	import game.components.motion.Magnet;
	import game.components.motion.Magnetic;
	import game.components.motion.nape.NapeSpace;
	import game.creators.motion.nape.NapeCreator;
	import game.creators.ui.ButtonCreator;
	import game.scene.template.NapeGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.nape.NapeMagnetSystem;
	import game.util.EntityUtils;
	import game.util.Utils;
	
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.space.Space;
	
	public class NapeMagnets extends PlatformerGameScene
	{
		public function NapeMagnets()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/napeMagnets/";
			
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
			setup();
			
			super.loaded();
		}
		
		// all assets ready
		private function setup():void
		{				
			// The NapeGroup adds the nape motion systems, creator and the main nape space entity.
			_napeGroup = new NapeGroup();
			_napeGroup.setupGameScene(this, _debug);
			
			var areaWidth:int = super.sceneData.bounds.width;
			var areaHeight:int = super.sceneData.bounds.height;
			var inputEntity:Entity = shellApi.inputEntity;
			var input:Input = inputEntity.get(Input) as Input;						
			var spaceEntity:Entity = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY);
			var napeSpace:NapeSpace = spaceEntity.get(NapeSpace);
			var boxSize:int = 48;  // make bodies slightly smaller than box art to allow some overlap
			var x:int;
			var y:int;
			
			for (var i:int = 0; i < 10; i++) 
			{	
				x = 1400 + Utils.randNumInRange(-5, 5);
				y = areaHeight - boxSize * i;
				// boxes have centered reg. points (both in Nape and in the art), so need to be positioned half of their size up.
				addMagnetic("magnetic0.swf", x, y - boxSize * .5, boxSize, napeSpace.space, 0);
			}
			
			for (i = 0; i < 10; i++) 
			{	
				x = 600 + Utils.randNumInRange(-5, 5);
				y = areaHeight - boxSize * i;
				// boxes have centered reg. points (both in Nape and in the art), so need to be positioned half of their size up.
				addMagnetic("magnetic1.swf", x, y - boxSize * .5, boxSize, napeSpace.space, 1);
			}
						
			addColliderToPlayer();
			
			addMagnet(super.hitContainer["magnetLeftSource"], 1, "magnetLeft");
			addMagnet(super.hitContainer["magnetRightSource"], 0, "magnetRight");
			
			super.addSystem(new NapeMagnetSystem());
			
			setupButtons();
		}
		
		private function addMagnet(displayObject:MovieClip, polarity:int, id:String):void
		{
			displayObject.field.gotoAndStop(polarity + 1);
			
			displayObject.scaleX = 5;
			displayObject.scaleY = 5;
			
			var force:Number = 10000;
			var display:Display = new Display(displayObject);
			display.isStatic = true;
			var entity:Entity = new Entity();
			entity.add(new Magnet(force, displayObject.width * .5, polarity));
			entity.add(new Spatial(displayObject.x, displayObject.y));
			entity.add(display);
			entity.add(new Id(id));
			_napeGroup.addEntity(entity);
		}
		
		private function addMagnetic(asset:String, x:int, y:int, size, space:Space, polarity:int):void
		{
			var box:Body = new Body(BodyType.DYNAMIC);
			box.shapes.add(new Polygon(Polygon.box(size, size)));
			
			var entity:Entity = _napeGroup.creator.createNapeObject(x, y, space, box);
			entity.add(new Magnetic(polarity));
			
			// uncomment and comment out the 'createNapeObject' line to make a magnetic object with standard motion.
			/*
			var entity:Entity = new Entity();
			entity.add(new Spatial(x, y));
			entity.add(new Motion());
			*/
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, super.groupPrefix + asset, entity, this, setupNapeObject);
		}
		
		private function setupNapeObject(display:MovieClip, entity:Entity):void
		{
			if(_debug)
			{
				Display(entity.get(Display)).visible = false;
			}
			
			// move width/height setting here too
			_napeGroup.addEntity(entity);
		}
		
		private function addColliderToPlayer():void
		{
			// create a nape body to map to the player.
			var playerBody:Body = new Body(BodyType.DYNAMIC);
			playerBody.shapes.add(new Polygon(Polygon.box(40, 80)));
			// mass in nape is determined by size by default.  For a box of this size it would be about 10.  
			//  We override this here to allow the player to push boxes without passing through them.
			//  Depending on the scenario this may have to be adjusted up or down.
			playerBody.mass = 100;
			
			_napeGroup.makeNapeCollider(super.player, playerBody);
			
			// make the player a magnet
			var force:Number = 10000;
			super.player.add(new Magnet(force, 250, 1));
		}
		
		private function setupButtons():void
		{
			//polarityToggleLeftText
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 12, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).polarityToggleLeftButton, this, Command.create(togglePolarity, "magnetLeft") );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).polarityToggleLeftButton, "Toggle Left Polarity", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).polarityToggleRightButton, this, Command.create(togglePolarity, "magnetRight") );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).polarityToggleRightButton, "Toggle Right Polarity", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).polarityTogglePlayerButton, this, Command.create(togglePolarity, "player") );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).polarityTogglePlayerButton, "Toggle Player Polarity", labelFormat, ButtonCreator.ORIENT_CENTERED);
			//MovieClip(super._hitContainer).timestepToggleLight.gotoAndStop("on");
		}
		
		private function togglePolarity(button:Entity, id:String):void
		{
			var magnetEntity:Entity = _napeGroup.getEntityById(id);
			
			if(magnetEntity == null)
			{
				magnetEntity = super.getEntityById(id);
			}
			
			var magnet:Magnet = magnetEntity.get(Magnet);
			var label:String;
			
			if(magnet.polarity)
			{
				magnet.polarity = 0;
				label = "0";
			}
			else if(!magnet.polarity && magnet.active)
			{
				magnet.active = false;
				label = "off";
			}
			else
			{
				magnet.polarity = 1;
				magnet.active = true;
				label = "1";
			}
			
			var display:Display = magnetEntity.get(Display);
			
			if(display.displayObject["field"] != null)
			{
				if(magnet.active)
				{
					display.visible = true;
					display.displayObject["field"].gotoAndStop(magnet.polarity + 1);
				}
				else
				{
					display.visible = false;
				}
			}
			
			super._hitContainer[id].text = label;
		}
		
		
		private var _napeGroup:NapeGroup;
		private var _debug:Boolean = false;
	}
}