package game.scenes.carnival.apothecary.components
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.scenes.carnival.apothecary.ReactorPopup;
	import game.scenes.carnival.apothecary.chemicals.Bubble;
	import game.scenes.carnival.apothecary.chemicals.Compound;
	import game.scenes.carnival.apothecary.chemicals.IChem;
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.chemicals.data.Compounds;
	import game.util.AudioUtils;
	
	import nape.callbacks.CbEvent;
	import nape.callbacks.CbType;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.callbacks.PreCallback;
	import nape.callbacks.PreFlag;
	import nape.callbacks.PreListener;
	import nape.dynamics.CollisionArbiter;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.shape.Shape;
	import nape.space.Space;
	import nape.util.ShapeDebug;
	
	public class Molecules extends Component
	{
		public function Molecules($display:Sprite, $popup:ReactorPopup, $formula:String = "salt", $numGroups:int = 5):void{
			display = $display;
			
			_popup = $popup;
			
			initPhysics();
			initChemicals($formula, $numGroups);
			
			if(!DEBUG){
				initBubbles();
			}
		}
		
		private function initPhysics():void{
			
			// create space (where the physics magic happens)
			if(!DEBUG){
				space = new Space(new Vec2(0, 100));
			} else {
				space = new Space(new Vec2(0, 0));
			}
			
			// create interaction listener (for collisions)
			ballCollisionType = new CbType();
			eBallCollisionType = new CbType();
			wallCollisionType = new CbType();
			bubbleCollisionType = new CbType();
			rBubbleCollisionType = new CbType();
			teleporterType = new CbType();
			
			// chemical collisions
			_interactionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, ballCollisionType, ballCollisionType, chemToChem);
			space.listeners.add(_interactionListener);
			
			// teleporter collisions
			space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, bubbleCollisionType, teleporterType, handleTeleport));
			
			// destroyer collisions
			space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, rBubbleCollisionType, teleporterType, destroyBubble));
			
			// bubble-wall collisions
			space.listeners.add(new PreListener(InteractionType.COLLISION, wallCollisionType, bubbleCollisionType, bubbleToWall, 0, true));
			space.listeners.add(new PreListener(InteractionType.COLLISION, wallCollisionType, rBubbleCollisionType, bubbleToWall, 0, true));
			
			// eBall-wall collisions
			space.listeners.add(new PreListener(InteractionType.COLLISION, wallCollisionType, eBallCollisionType, bubbleToWall, 0, true));
			space.listeners.add(new PreListener(InteractionType.COLLISION, teleporterType, eBallCollisionType, bubbleToWall, 0, true));
			
			// bubble-ball collisions
			//space.listeners.add(new PreListener(InteractionType.COLLISION, ballCollisionType, bubbleCollisionType, bubbleToBall, 0, true));
			
			// setup debugger
			if (DEBUG) {
				shapeDebug = new ShapeDebug(1200,1200);
				shapeDebug.drawConstraints = true;
				display.addChild(shapeDebug.display);
			}
			
			// create box for chemicals to bounce around in
			box = new Body(BodyType.KINEMATIC);
			var p:Polygon;
			
			_botWall = new Polygon (
				Polygon.rect(
					65, 	// x position
					599, 	// y position
					684, 	// width
					10		// height
				)
			);
			
			box.shapes.add(_botWall);
			
			p = new Polygon (
				Polygon.rect(
					749, 	// x position
					96, 	// y position
					10, 	// width
					513		// height
				)
			);
			
			box.shapes.add(p);
			
			p = new Polygon (
				Polygon.rect(
					55, 	// x position
					96, 	// y position
					10, 	// width
					513		// height
				)
			);
			
			box.shapes.add(p);
			
			_topWall = new Polygon (
				Polygon.rect(
					65, 	// x position
					96, 	// y position
					684, 	// width
					10		// height
				)
			);
			
			box.shapes.add(_topWall);
			
			// create circle collision for the knob
			var c:Circle = new Circle(58, new Vec2(718,352));
			box.shapes.add(c);
			box.cbTypes.add(wallCollisionType);
			
			// add box to nape space
			space.bodies.add(box);
			
			// add fluid in the box
			var fluidBody:Body = new Body(BodyType.STATIC);
			var fluidShape:Shape = new Polygon(Polygon.rect(-600,0,2000,1000));
			
			fluidShape.filter.collisionMask = 0;
			fluidShape.fluidEnabled = true;
			fluidShape.filter.fluidMask = 2;
			
			fluidShape.fluidProperties.density = 22;
			fluidShape.fluidProperties.viscosity = 6;
			
			fluidShape.body = fluidBody;
			fluidBody.space = space;
			
			// add teleporter border (to transport bubbles back down to the bottom of the tank)
			
			var border:Body = new Body(BodyType.STATIC);
			border.shapes.add(new Polygon(Polygon.rect(-600, 40, 2000, 10)));
			border.cbTypes.add(teleporterType);
			border.space = space;
			
		}
		
		public function initChemicals($formula:String, $numGroups):void{
			// create chemical groups
			var c:int;
			
			switch($formula){
				case "salt":
					for(c = 0; c < $numGroups; c++){
						Compound.newCompound(Compounds.SODIUM_HYDROXIDE, this);
						Compound.newCompound(Compounds.HYDROCHLORIC_ACID, this);
					}
					break;
				case "sugar":
					for(c = 0; c < $numGroups; c++){
						Compound.newCompound(Compounds.FRUCTOSE, this);
						Compound.newCompound(Compounds.GLUCOSE, this);
					}
					break;
				case "sodiumThiopental":
					for(c = 0; c < $numGroups; c++){
						Compound.newCompound(Compounds.ETHLYMALONIC_ESTER, this);
						Compound.newCompound(Compounds.BROMOPENTANE, this);
						Compound.newCompound(Compounds.SODIUM_SULFIDESODIUM, this);
					}
					break;
				case "chemX":
					for(c = 0; c < $numGroups; c++){
						Compound.newCompound(Compounds.MUSHROOM, this);
						Compound.newCompound(Compounds.PICKLE_JUICE, this);
						Compound.newCompound(Compounds.COLA, this);
					}
			}
			
			_sReactions = 0;
			_sReactionsMAX = compounds.length;
			
			_popup.updateReactionNum(_sReactionsMAX, _sReactions);
		}
		
		public function initBubbles($numGroups:int = 8):void{
			// create bubbles (stirs chemicals around)
			for(var c:int = 0; c < $numGroups; c++){
				bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_1, this));
				bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_2, this));
				bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_3, this));
			}
		}
		
		private function chemToChem($intCB:InteractionCallback):void
		{
			/**
			 * Occurs on chemical to chemical body collisions in nape
			 * Check if chemicals are free
			 * Check if chemicals react
			 * If so, bond them into new compounds
			 */
			
			var bodyA:Body = $intCB.int1.castBody as Body;
			var bodyB:Body = $intCB.int2.castBody as Body;
			
			var chemA:IChem = getChemFromBody(bodyA);
			var chemB:IChem = getChemFromBody(bodyB);
			
			var compound:Compound;
			
			// check if reaction possible
			if(chemA.reactive && chemB.reactive){
				
				var reactObj:Object;
				var chem:IChem;
				
				// check chem A
				for each(reactObj in chemA.reactions){
					if(reactObj.reactsWith == chemB.thisClass){ // ERROR: need to check if chems sides react with each other, not just 1 side
						for each(reactObj in chemB.reactions){
							if(reactObj.reactsWith == chemA.thisClass){
								try{
									// check if chemicals already in a compound
									if(chemA.compound == null && chemB.compound == null){ // both free chemicals
										
										// create compound in correct bisecting order
										if(chemA.position == "left"){
											compound = Compound.createCompound(chemA, chemB, this);
										} else if(chemA.position == "right"){
											compound = Compound.createCompound(chemB, chemA, this);
										} else if(chemB.position == "left"){
											compound = Compound.createCompound(chemB, chemA, this);
										} else if(chemB.position == "right"){
											compound = Compound.createCompound(chemA, chemB, this);
										}
										
										// update reactions and chemicals
										removeReaction(chemA, chemB.thisClass);
										removeReaction(chemB, chemA.thisClass);
										
										// check if complete - and add to list if it is
										if(chemA.reactive == false && chemB.reactive == false && compound != null){
											compound.complete = true; // complete compound 
											compounds.push(compound); // add to compounds list
											_sReactions++; // tick successful reactions
											
											// make molecule ethereal
											for each(chem in compound.chemicals){
												chem.changeCBType(eBallCollisionType);
											}
										}
										
									} else { // chem in unfinished compound(3) add to already existing compound
										if(chemA.compound != null){
											compound = chemA.compound;
											Compound.addToCompound(compound, chemB, this);
										} else if(chemB.compound != null){
											compound = chemB.compound;
											Compound.addToCompound(compound, chemA, this);
										}
										
										// update reactions and chemicals
										removeReaction(chemA, chemB.thisClass);
										removeReaction(chemB, chemA.thisClass);
										
										// complete compound
										compound.complete = true; // complete compound 
										compounds.push(compound); // add to compounds list
										_sReactions++; // tick successful reactions
										
										// make molecule ethereal
										for each(chem in compound.chemicals){
											chem.changeCBType(eBallCollisionType);
										}
									}
									
									checkReactions();
									
								} catch($error:Error){
									trace($error.getStackTrace());
								}
							}
						}
					}
				}
			}
			
			function removeReaction($chem:IChem, $chemClass:Class):void{
				// remove reaction
				for(var r:int = 0; r < $chem.reactions.length; r++){
					if($chem.reactions[r].reactsWith == $chemClass){
						trace("removing reaction: "+$chem.reactions[r].reactsWith+" from "+$chem.thisClass+"'s reactions");
						$chem.reactions.splice(r, 1);
						trace($chem.reactions.length);
					}
				}
				
				// check if inert
				if($chem.reactions.length == 0){
					// make inert
					$chem.reactive = false; 
					$chem.removeCollisions();
					
					// remove from chemicals check list
					for(var c:int = 0; r < chemicals.length; r++){
						if(chemicals[c] == $chem){
							chemicals.splice(c, 1);
						}
					}
				}
			}
			
			function checkReactions():void{
				
				_popup.updateReactionNum(_sReactionsMAX, _sReactions);
				
				_popup.reactLight();
				if(_sReactions >= _sReactionsMAX){
					_popup.shellApi.triggerEvent("reactDone");
					flushChems();
				} else {
					_popup.shellApi.triggerEvent("react");
				}
			}
		}
		
		private function bubbleToWall($collision:PreCallback):PreFlag{
			var colArb:CollisionArbiter = $collision.arbiter.collisionArbiter;
			return PreFlag.IGNORE;
		}
		
		private function bubbleToBall($collision:PreCallback):PreFlag{
			var colArb:CollisionArbiter = $collision.arbiter.collisionArbiter;
			return PreFlag.IGNORE;
		}
		
		private function handleTeleport($collision:InteractionCallback):void
		{
			var object:Body = $collision.int1.castBody;
			
			// return to bottom
			object.position = new Vec2((Math.random()*684)+65, 700);
		}
		
		private function destroyBubble($collision:InteractionCallback):void{
			var object:Body = $collision.int1.castBody;
			
			// remove body from the space
			object.space = null;
			
			// remove object from display list
			var bubble:Bubble = getBubbleFromBody(object);
			bubble.destroy(bubbles);
		}
		
		private function getChemFromBody($body:Body):IChem{
			for each(var chem:IChem in chemicals){
				if(chem.body == $body){
					return chem;
				}
			}
			
			return null;
			
		}
		
		private function getBubbleFromBody($body:Body):Bubble{
			for each(var bubble:Bubble in bubbles){
				if(bubble.body == $body){
					return bubble;
				}
			}
			
			return null;
		}
		
		public function flushChems():void{
			_popup.shellApi.triggerEvent("flush");
			_popup.finishReaction();
			
			// add gravity
			//space.gravity = new Vec2(0, 300);
			
			// remove bottom wall
			//box.shapes.remove(_botWall);
		}
		
		public function popCatalyst($point:Point):void{
			
			_popup.gun.gotoAndPlay("fire");
			
			AudioUtils.play(_popup, SoundManager.EFFECTS_PATH + "chemBurst.mp3");
			
			var radius:Number = 100;
			// atan2(deltaY, deltaX)
			
			var chemPoint:Point;
			
			if(!DEBUG){
				bubbleBurst($point);
			}
			
			// check compounds to "break"
			for each(var compound:Compound in compounds){
				
				if(!compound.complete){ // if a breakable compound, break it
					var breakCompound:Boolean = false;
					var angle:Number;
					
					// check if any compounds' chemicals are within range of pop
					for each(var cchem:IChem in compound.chemicals){
						chemPoint = new Point(cchem.body.position.x, cchem.body.position.y);
						if(Point.distance(chemPoint, $point) <= radius){
							breakCompound = true
						}
					}
					
					if(breakCompound){
						// play broken compound sound
						//_popup.shellApi.triggerEvent("break");
						
						// add broken chems into chemicals vector
						for each(cchem in compound.chemicals){
							chemicals.push(cchem);
						}
						
						// break bonds and destroy compound
						compound.breakCompound(compounds);
					}
				} else { // if not breakable, nudge it
					for each(var nchem:IChem in compound.chemicals){
						chemPoint = new Point(nchem.body.position.x, nchem.body.position.y);
						if(Point.distance(chemPoint, $point) <= radius){
							angle = Math.atan2(chemPoint.y - $point.y, chemPoint.x - $point.x);
							nchem.body.velocity = new Vec2(200*Math.cos(angle),200*Math.sin(angle));
						}
					}
				}
			}
			
			// check chemical components to nudge
			for each(var chem:IChem in chemicals){
				chemPoint = new Point(chem.body.position.x, chem.body.position.y);
				if(Point.distance(chemPoint, $point) <= radius){
					angle = Math.atan2(chemPoint.y - $point.y, chemPoint.x - $point.x);
					chem.body.velocity = new Vec2(200*Math.cos(angle),200*Math.sin(angle));
				}
			}
			
		}
		
		public function bubbleBurst($point:Point):void{
			bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_1, this, $point, true));
			bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_1, this, $point, true));
			bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_1, this, $point, true));
			bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_2, this, $point, true));
			bubbles.push(new Bubble(ChemicalGraphics.BUBBLE_3, this, $point, true));
		}
		
		public function updateGun():void{
			var spatial:Spatial = _popup.gunEntity.get(Spatial);
			
			var angle:Number = Math.atan2(_popup.screen.content.gun.y - _popup.screen.content.mouseY, _popup.screen.content.gun.x - _popup.screen.content.mouseX);
			var degrees:Number = angle * (180/Math.PI);
			
			if(degrees <= 90 && degrees >= -90){
				var tween:Tween = _popup.gunEntity.get(Tween);
				tween.to(_popup.gunEntity.get(Spatial), 1, {rotation:degrees});
			}
		}
		
		public function devTest():void{
			
		}
		
		public var display:Sprite;
		
		// nape debug
		public const DEBUG:Boolean = false;
		public var shapeDebug:ShapeDebug; // display for the debug
		
		// nape environment
		public var space:Space;
		public var box:Body;
		
		private var _topWall:Polygon;
		private var _botWall:Polygon;
		
		// listener
		private var _interactionListener:InteractionListener;
		private var _wallCollisionListener:InteractionListener;
		public var ballCollisionType:CbType;
		public var wallCollisionType:CbType;
		public var bubbleCollisionType:CbType;
		public var rBubbleCollisionType:CbType;
		public var teleporterType:CbType;
		public var eBallCollisionType:CbType;
		
		// misc
		public var popPoint:Point;
		private var _popup:ReactorPopup;
		public var _sReactions:int;
		private var _sReactionsMAX:int;
		
		// chemicals
		public var compounds:Vector.<Compound> = new Vector.<Compound>; // molecules
		public var chemicals:Vector.<IChem> = new Vector.<IChem>; // free floating chemicals (not bonded)
		public var bubbles:Vector.<Bubble> = new Vector.<Bubble>; // bubbles traveling up
		
	}
}