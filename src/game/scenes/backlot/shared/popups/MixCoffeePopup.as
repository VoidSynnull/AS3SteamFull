package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.ui.popup.Popup;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class MixCoffeePopup extends Popup
	{
		public function MixCoffeePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/shared/";
			super.screenAsset = "mixCoffee.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			setUp();
			
			super.loadCloseButton();
		}
		
		private var backlot:BacklotEvents;
		
		private var content:MovieClip;
		
		private var menuArray:Array = ["Espresso","Macchiato","Con Panna","Latte","Mocha","Americano","Cappuccino", "Cup"];
		private var sizeArray:Array = ["Behemoth","Leviathan","Infant"];
		private var caffArray:Array = ["Mega-Caf","Super-Caf","Full-Caf","Half-Caf","Decaf", "Empty"];
		private var caffColor:Array = ["0x4E341C","0x71462B","0x905A36","0xC46824","0xDC813E"];
		private var cupNames:Array = [3];
		private var cupOunces:Array = [3];
		private var maxOunces:Array = [3];
		private var cupCaffine:Array = [3];
		private var cupFlavor:Array = [3];
		private var cupSize:Array = [3];
		private var saveStrings:Array = [3];
		private var coffeeName:TextField;
		private var kirksCup:Entity;
		
		private var POUR:String = "POURING...";
		
		private var cupStartPositions:Vector.<Point> = new Vector.<Point>();
		
		private function setUp():void
		{
			shellApi.removeEvent(backlot.KIRK_CUP_FILLED);
			shellApi.removeEvent(backlot.MADE_TO_ORDER);
			content = screen.content as MovieClip;
			coffeeName = content.coffeename;
			
			layout.centerUI(content);
			
			var resetButton:Entity = EntityUtils.createSpatialEntity(this, content.reset_btn,content);
			var interaction:Interaction = InteractionCreator.addToEntity(resetButton,[InteractionCreator.CLICK],content.reset_btn);
			interaction.click.add(reset);
			ToolTipCreator.addToEntity(resetButton);
			
			var saveButton:Entity = EntityUtils.createSpatialEntity(this, content.save_btn,content);
			interaction = InteractionCreator.addToEntity(saveButton,[InteractionCreator.CLICK],content.save_btn);
			interaction.click.add(save);
			ToolTipCreator.addToEntity(saveButton);
			
			var talky:Entity = EntityUtils.createSpatialEntity(this,content.talky,content);
			talky.add(new Id("talky"));
			TimelineUtils.convertClip(content.talky, this, talky, null, false);
			
			for(var i:int = 0; i < 3; i++)
			{
				// save goes: menu, size, caff // will look something like #|#|#
				
				if(i == 1)
					saveStrings[1] = 7 + "," + 1 + "," + 5;// always defaults to empty to avoid overfilling cup
				else
					saveStrings[i] = shellApi.getUserField("coffee"+i,shellApi.island);
				
				var info:Array = String(saveStrings[i]).split(",");
				
				cupSize[i] = int(info[1]);
				
				cupOunces[i] = 8 * (3 - int(info[1]));
				maxOunces[i] = cupOunces[i];
				
				cupCaffine[i] = [];
				cupCaffine[i].push(int(info[2]));
				
				var flavors:Array = String(info[0]).split(".")
				
				cupFlavor[i] = flavors;
				
				cupNames[i] = interpretCoffeeName(i);
				
				var cupClip:MovieClip;
				
				cupClip = content["b"+i];
				
				var cup:Entity = EntityUtils.createSpatialEntity(this, cupClip, content);
				cup.add(new Id("cup"+i));
				
				var coffee:Entity = EntityUtils.createSpatialEntity(this, cupClip.clr,cupClip);
				coffee.add(new Id("coffee"+i));
				Display(coffee.get(Display)).displayObject.mask = cupClip.liquidCover;
				DisplayUtils.moveToOverUnder(cupClip.clr, cupClip.back);
				///*
				var glow:Entity = EntityUtils.createSpatialEntity(this, cupClip.glow,cupClip);
				glow.add(new Id("glow"+i));
				DisplayUtils.moveToOverUnder(cupClip.glow, cupClip.back, false);
				Display(glow.get(Display)).alpha = 0;
				//*/
				var pour:Entity = EntityUtils.createSpatialEntity(this,cupClip.fluid,cupClip);
				TimelineUtils.convertClip(cupClip.fluid, this, pour,null,false);
				pour.add(new Id("pour"+i));
				DisplayUtils.moveToOverUnder(cupClip.fluid, cupClip.hit,false);
				Display(pour.get(Display)).displayObject.mask = content.pouringMask;
				Display(pour.get(Display)).visible = false;
				
				if(caffArray[int(info[2])] == "Empty")
				{
					cupOunces[i] = 0;
					Spatial(coffee.get(Spatial)).height = 0;
				}
				else
					changeCoffeeColor(i);
				
				content["t"+i].text = cupOunces[i] + " OUNCES";
				
				if(i == 1)
				{
					coffeeName.text = cupNames[1];
					kirksCup = cup;
					interaction = InteractionCreator.addToEntity(kirksCup, [InteractionCreator.OVER, InteractionCreator.OUT],cupClip);
					interaction.over.add(mouseOverCup);
					interaction.out.add(mouseOutCup);
					DisplayUtils.moveToOverUnder(cupClip, Display(getEntityById("cup0").get(Display)).displayObject,false);
				}
				else
				{
					interaction = InteractionCreator.addToEntity(cup, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.OUT],cupClip);
					interaction.down.add(clickCup);
					interaction.up.add(releaseCup);
					interaction.over.add(mouseOverCup);
					interaction.out.add(mouseOutCup);
				}
				
				ToolTipCreator.addToEntity(cup);
				
				cupStartPositions.push(new Point(cup.get(Spatial).x, cup.get(Spatial).y));
			}
		}
		
		private function reset(entity:Entity):void
		{
			shellApi.removeEvent(backlot.KIRK_CUP_FILLED);
			Spatial(getEntityById("talky").get(Spatial)).scale = .01;
			for(var i:int = 0; i < 3; i++)
			{
				var info:Array = String(saveStrings[i]).split(",");
				
				cupSize[i] = int(info[1]);
				
				cupOunces[i] = 8 * (3 - int(info[1]));
				maxOunces[i] = cupOunces[i];
				
				cupCaffine[i] = [];
				cupCaffine[i].push(int(info[2]));
				
				var flavors:Array = String(info[0]).split("-")
				cupFlavor[i] = flavors;
				
				var coffee:Entity = getEntityById("coffee"+i);
				Display(getEntityById("glow"+i).get(Display)).alpha = 0;
				
				var cupHeight:Number = 24 + 7 * cupOunces[i];
				
				if(caffArray[int(info[2])] == "Empty")
				{
					cupOunces[i] = 0;
					cupHeight = 0;
				}
				
				Spatial(coffee.get(Spatial)).height = cupHeight;
				
				content["t"+i].text = cupOunces[i] + " OUNCES";
				
				changeCoffeeName(i);
			}
			
			coffeeName.text = cupNames[1];
		}
		
		private function save(entity:Entity):void
		{
			if(!kirksCupIsFilled())
			{
				return;
			}
			shellApi.completeEvent(backlot.KIRK_CUP_FILLED);
			shellApi.removeItem(backlot.COFFEE_CUP_LEFT);
			shellApi.removeItem(backlot.COFFEE_CUP_RIGHT);
			
			// save goes: menu, size, caff
			for(var i:int = 0; i < 3; i++)
			{
				saveStrings[i] = "[";
				for(var f:int = 0; f < cupFlavor[i].length; f++)
				{
					saveStrings[i] += cupFlavor[i][f];
					if(f == cupFlavor[i].length -1)
						break;
					saveStrings[i] += ".";
				}
				saveStrings[i] += "," + cupSize[i] +"," + cupCaffine[i][0]+"]";
				shellApi.setUserField("coffee"+i,saveStrings[i],shellApi.island,true);
			}
			
			if(checkIfCoffeeWasMadeRight())
				shellApi.completeEvent(backlot.MADE_TO_ORDER);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3,1,delayedClose));
		}
		
		private function delayedClose():void
		{
			super.close();
		}
		
		private function changeCoffeeColor(coffeeNumber:int):void
		{
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = caffColor[cupCaffine[coffeeNumber][0]];
			Display(getEntityById("coffee"+coffeeNumber).get(Display)).displayObject.transform.colorTransform = colorTransform;
			Display(getEntityById("pour"+coffeeNumber).get(Display)).displayObject.transform.colorTransform = colorTransform;
		}
		
		private function interpretCoffeeName(coffeeNumber:int):String
		{
			var name:String="";
			var caf:int = 0;
			
			for(var c:int = 0; c < cupCaffine[coffeeNumber].length; c++)
			{
				if(cupCaffine[coffeeNumber][c] > 4)
				{
					if(cupCaffine[coffeeNumber].length > 1)
					{
						cupCaffine[coffeeNumber].splice(c,1);
						c--;
						continue;
					}
					else
						caf = cupCaffine[coffeeNumber][c];
				}
				else
					caf += (4 - cupCaffine[coffeeNumber][c]);
			}
			
			caf/=cupCaffine[coffeeNumber].length;
			if(caf < 5)
				caf = 4 - caf;
			cupCaffine[coffeeNumber]=[];
			cupCaffine[coffeeNumber].push(caf);
			
			name+=caffArray[caf] + " " + sizeArray[cupSize[coffeeNumber]]  + " ";
			
			for(var i:int = 0; i < cupFlavor[coffeeNumber].length; i++)
			{
				if(cupFlavor[coffeeNumber][i] > 6)
				{
					if(cupFlavor[coffeeNumber].length > 1)
					{
						cupFlavor[coffeeNumber].splice(i,1);
						i--;
						continue;
					}
					else
						name += menuArray[cupFlavor[coffeeNumber][i]];
				}
				else
					name += menuArray[cupFlavor[coffeeNumber][i]];
				
				if(i == cupFlavor[coffeeNumber].length - 1)
					break;
				
				name+="-";
			}
			
			return name;
		}
		
		private function changeCoffeeName(coffeeNumber:int = 1, checkIfEmpty:Boolean = false):void
		{
			if(cupOunces[coffeeNumber] == 0 && checkIfEmpty)
			{
				cupCaffine[coffeeNumber] = [];
				cupCaffine[coffeeNumber].push(5);
				cupFlavor[coffeeNumber]=[];
				cupFlavor[coffeeNumber].push(7);
			}
			cupNames[coffeeNumber] = interpretCoffeeName(coffeeNumber);
			changeCoffeeColor(coffeeNumber);
		}
		
		private function mouseOutCup(cup:Entity):void
		{
			if(coffeeName.text == POUR)
				return;
			var coffeeNumber:int = parseInt(Id(cup.get(Id)).id.charAt(3));
			var glow:Entity = getEntityById("glow"+coffeeNumber);
			Display(glow.get(Display)).alpha = 0;
			coffeeName.text = cupNames[1];
		}
		
		private function mouseOverCup(cup:Entity):void
		{
			if(coffeeName.text == POUR)
				return;
			
			Spatial(getEntityById("talky").get(Spatial)).scale = .01;
			var coffeeNumber:int = parseInt(Id(cup.get(Id)).id.charAt(3));
			var glow:Entity = getEntityById("glow"+coffeeNumber);
			Display(glow.get(Display)).alpha = 1;
			coffeeName.text = cupNames[coffeeNumber];
		}
		
		private function releaseCup(cup:Entity):void
		{
			var kirksHitBox:Rectangle = Display(kirksCup.get(Display)).displayObject.getBounds(content);
			var coffeeNumber:int = parseInt(Id(cup.get(Id)).id.charAt(3));
			cup.remove(FollowTarget);
			
			if(kirksHitBox.contains(cup.get(Spatial).x, cup.get(Spatial).y))
			{
				startToPourCup(cup, coffeeNumber);
				return;
			}
			returnCup(cup, coffeeNumber);
		}
		
		private function startToPourCup(cup:Entity, coffeeNumber:int):void
		{
			SceneUtil.lockInput(this);
			coffeeName.text = "POURING...";
			
			var startPoint:Point = cupStartPositions[coffeeNumber];
			var offSetX:Number = 50
			var targetPoint:Point = new Point(cupStartPositions[1].x, cupStartPositions[1].y - 100);
			var targetRotation:Number = 90;
			if(startPoint.x > targetPoint.x)
			{
				targetPoint.x += offSetX;
				targetRotation *= -1;
			}
			else
			{
				targetPoint.x -= offSetX;
				Spatial(getEntityById("pour"+coffeeNumber).get(Spatial)).scaleX = -Math.abs(Spatial(getEntityById("pour"+coffeeNumber).get(Spatial)).scaleX);
				Spatial(getEntityById("pour"+coffeeNumber).get(Spatial)).x = Math.abs(Spatial(getEntityById("pour"+coffeeNumber).get(Spatial)).x);
			}
			
			if(cupOunces[coffeeNumber] == 0)
			{
				returnCup(cup, coffeeNumber);
				return;
			}
			
			var tween:Tween = new Tween();
			TweenUtils.entityTo(cup, Spatial,1,{x:targetPoint.x, y:targetPoint.y, rotation:targetRotation / 3, onComplete:Command.create(pourCup, cup, coffeeNumber, targetRotation)});
		}
		
		private function pourCup(cup:Entity, coffeeNumber:int, targetRotation:Number):void
		{
			if(caffArray[cupCaffine[coffeeNumber][0]] != "Empty")
			{
				cupFlavor[1].push(cupFlavor[coffeeNumber][0]);
				cupCaffine[1].push(cupCaffine[coffeeNumber][0]);
				changeCoffeeName();
			}
			
			var pourTime:Number = 2;
			
			var pourEntity:Entity = getEntityById("pour"+coffeeNumber);
			Display(pourEntity.get(Display)).visible = true;
			Display(pourEntity.get(Display)).displayObject.mask = content.pouringMask;
			
			var pourTimeline:Timeline = pourEntity.get(Timeline);
			
			pourTimeline.gotoAndPlay(0);
			
			pourTimeline.handleLabel("ending",Command.create(stopPouring, pourEntity));
			
			SceneUtil.addTimedEvent(this, new TimedEvent(pourTime/cupOunces[coffeeNumber],cupOunces[coffeeNumber],Command.create(pour, coffeeNumber)));
			
			var tween:Tween = new Tween();
			TweenUtils.entityTo(cup, Spatial,pourTime,{rotation:targetRotation});
			
			var cupHeight:Number = 24 + 7 * (cupOunces[1] + cupOunces[coffeeNumber]);
			
			var kirksCoffee:Entity = getEntityById("coffee1");
			
			var pouringCoffee:Entity = getEntityById("coffee" + coffeeNumber);
			
			TweenUtils.entityTo(getEntityById("coffee1"), Spatial,pourTime,{height:cupHeight});
			TweenUtils.entityTo(getEntityById("coffee"+coffeeNumber), Spatial,pourTime,{height:0});
		}
		
		private function stopPouring(pour:Entity):void
		{
			Timeline(pour.get(Timeline)).stop();
			Display(pour.get(Display)).visible = false;
		}
		
		private function pour(coffeeNumber:int):void
		{
			cupOunces[coffeeNumber] --;
			content["t"+coffeeNumber].text = cupOunces[coffeeNumber] + " OUNCES";
			
			cupOunces[1] ++;
			content["t1"].text = cupOunces[1] + " OUNCES";
			
			if(cupOunces[coffeeNumber] == 0)
				returnCup( getEntityById("cup"+coffeeNumber), coffeeNumber)
		}
		
		private function returnCup(cup:Entity, coffeeNumber:int):void
		{
			if(caffArray[cupCaffine[coffeeNumber][0]] != "Empty")
				changeCoffeeName(coffeeNumber, true);
			
			var tween:Tween = new Tween();
			TweenUtils.entityTo(cup, Spatial,1,{x:cupStartPositions[coffeeNumber].x, y:cupStartPositions[coffeeNumber].y, rotation:0, onComplete:returnedCup});
		}
		
		private function returnedCup():void
		{
			coffeeName.text = cupNames[1];
			
			SceneUtil.lockInput(this, false);
			
			if(checkIfCoffeeWasMadeRight())
				save(null);
		}
		
		private function checkIfCoffeeWasMadeRight():Boolean
		{
			if(!kirksCupIsFilled())
				return false;
			
			var talky:Entity  = getEntityById("talky");
			
			TweenUtils.entityTo(talky, Spatial,1,{scale:1});
			
			if(cupNames[1] == "Half-Caf Leviathan Espresso-Latte" || cupNames[1] == "Half-Caf Leviathan Latte-Espresso")
			{
				return true;
			}
			Timeline(talky.get(Timeline)).gotoAndStop(1);
			return false;
		}
		
		private function kirksCupIsFilled():Boolean
		{
			if(cupOunces[1] < 16)
				return false;
			return true;
		}
		
		private function clickCup(cup:Entity):void
		{
			var follow:FollowTarget = new FollowTarget(shellApi.inputEntity.get(Spatial));
			follow.offset = new Point(-content.x, -content.y);
			cup.add(follow);
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
	}
}