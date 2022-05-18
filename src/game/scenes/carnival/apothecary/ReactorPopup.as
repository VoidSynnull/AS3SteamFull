package game.scenes.carnival.apothecary
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	import game.scenes.carnival.apothecary.systems.MoleculesSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	
	import org.osflash.signals.Signal;
	
	public class ReactorPopup extends Popup
	{
		public function ReactorPopup(container:DisplayObjectContainer=null, $formula:String = null)
		{
			_formula = $formula;
			super(container);
			getProduct = new Signal();
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			MovieClip(super.screen.content).removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight - 150);
			
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/carnival/apothecary/";
			super.init(container);
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			//super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["reactorPopup.swf"],false,true,loaded);
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset("reactorPopup.swf", true) as MovieClip;
			
			//DisplayPositionUtils.centerWithinDimensions(this.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 986, 733.45);
			//this.fitToDimensions(this.screen.background, true);
			
			// this loads the standard close button
			super.loadCloseButton();
			super.loaded();
			
			initGraphics();
			initEntities();
			initSystems();
			initAudio();
			initAnnimation();
			
			super.screen.content.chemHolder.mouseChildren = false;
			super.screen.content.chemHolder.mouseEnabled = false;
		}
		
		private function initAudio():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "chemTank_loop.mp3", 1, true);
		}
		
		private function initGraphics():void{
			gun = super.screen.content.gun;
			
			ChemicalGraphics.H_GRAPHIC = super.screen.H;
			ChemicalGraphics.OH_GRAPHIC = super.screen.OH;
			ChemicalGraphics.CL_GRAPHIC = super.screen.Cl;
			ChemicalGraphics.NA_GRAPHIC = super.screen.Na;
			ChemicalGraphics.FR_GRAPHIC = super.screen.fructose;
			ChemicalGraphics.GL_GRAPHIC = super.screen.glucose;
			ChemicalGraphics.BR_GRAPHIC = super.screen.Br;
			ChemicalGraphics.P1_GRAPHIC = super.screen.p1;
			ChemicalGraphics.P2_GRAPHIC = super.screen.p2;
			ChemicalGraphics.P3_GRAPHIC = super.screen.p3;
			ChemicalGraphics.X1_GRAPHIC = super.screen.x1;
			ChemicalGraphics.X2_GRAPHIC = super.screen.x2;
			ChemicalGraphics.X3_GRAPHIC = super.screen.x3;
			
			ChemicalGraphics.BUBBLE_1 = super.screen.bubble1;
			ChemicalGraphics.BUBBLE_2 = super.screen.bubble2;
			ChemicalGraphics.BUBBLE_3 = super.screen.bubble3;
		}
		
		private function initEntities():void{
			moleculesEntity  = new Entity();
			
			super.screen.content.infoText.formula = _formula;
			
			switch(_formula){
				case "salt":
					moleculesEntity.add(new Molecules(super.screen.content, this, "salt", 5));
					break;
				case "sugar":
					moleculesEntity.add(new Molecules(super.screen.content, this, "sugar", 4));
					break;
				case "sodiumThiopental":
					moleculesEntity.add(new Molecules(super.screen.content, this, "sodiumThiopental", 3));
					break;
				case "chemX":
					moleculesEntity.add(new Molecules(super.screen.content, this, "chemX", 4));
					break;
				default :
					moleculesEntity.add(new Molecules(super.screen.content, this));
					break;
			}
			
			super.addEntity(moleculesEntity);
			
			gunEntity = new Entity();
			gunEntity.add(new Display(super.screen.content.gun));
			gunEntity.add(new Spatial());
			gunEntity.add(new Tween());
			
			super.addEntity(gunEntity);
			
			clickSurface = ButtonCreator.createButtonEntity(super.screen.content.clickSurface, this, onClickSurface, null, null, ToolTipType.TARGET);
		}
		
		private function initAnnimation():void
		{
			//this.screen.content.cacheAsBitmap = true;
			
			this.screen.content.gun.cacheAsBitmap = true;
			this.screen.content.gun.mouseEnabled = false;
			this.screen.content.gun.mouseChildren = false;
			
			//MovieClip(super.screen.content).addEventListener(MouseEvent.MOUSE_MOVE, onMove);
		}
		
		private function onMove($event:MouseEvent):void{
			var angle:Number = Math.atan2(this.screen.content.mouseY - this.screen.content.gun.y, this.screen.content.mouseX - this.screen.content.gun.x);
			this.screen.content.gun.rotation = angle * (180/Math.PI) + 180;
		}
		
		private function onClickSurface($entity:Entity):void{
			Molecules(moleculesEntity.get(Molecules)).popCatalyst(new Point(super.screen.content.mouseX, super.screen.content.mouseY));
		}
		
		public function updateReactionNum($reagents:int, $products:int):void{
			// update text in the metrics on the lower left.
			var rTenDigit:int = Math.floor($reagents / 10);
			var rSigDigit:int = $reagents - (rTenDigit * 10);
			var pTenDigit:int = Math.floor($products / 10);
			var pSigDigit:int = $products - (pTenDigit * 10);
			
			this.screen.content.metrics.rDigit1.gotoAndStop(rTenDigit + 1);
			this.screen.content.metrics.rDigit2.gotoAndStop(rSigDigit + 1);
			this.screen.content.metrics.pDigit1.gotoAndStop(pTenDigit + 1);
			this.screen.content.metrics.pDigit2.gotoAndStop(pSigDigit + 1);
		}
		
		public function reactLight():void{
			this.screen.content.reactionLight.gotoAndPlay(2);
		}
		
		private function initSystems():void{
			super.addSystem(new MoleculesSystem(super.screen.content, this));
		}
		
		public function finishReaction():void{
			if(_formula != null){
				getProduct.dispatch(this, _formula);
			}
			this.close();
		}
		
		public var gun:MovieClip;
		
		private var clickSurface:Entity;
		private var moleculesEntity:Entity;
		public var gunEntity:Entity;
		
		public var getProduct:Signal;
		
		private var _formula:String;
		
	}
}