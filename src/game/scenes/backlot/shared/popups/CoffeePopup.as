package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.ui.popup.Popup;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class CoffeePopup extends Popup
	{
		
		public function CoffeePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/shared/";
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["CoffeePopup.swf"]);
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset("CoffeePopup.swf", true) as MovieClip;
			
			super.layout.centerUI(super.screen.content);
			
			setUpCoffeeMachine();			
			
			super.loaded();
			super.loadCloseButton();
		}
		
		private function setUpCoffeeMachine():void
		{
			content = super.screen.content as MovieClip;
			content.funfact.visible = false;
			content.pleasewait.visible = false;
			_coffee = content.cup_mc;
			_coffee.gotoAndStop(1);
			content.s2.gotoAndStop(2);
			_size = 2;
			
			createCaffeineOptions();
			
			setUpBuyButton();
			
			trace(super.shellApi.sceneName);
			if( super.shellApi.sceneName == "CoffeeShopRight" )
			{
				_right = true;
				content.soldoutespresso.visible = false;
				chooseCaffeineOption(super.getEntityById("decaf"));
			}
			else
			{
				_right = false;
				content.soldoutlatte.visible = false;
				chooseCaffeineOption(super.getEntityById("full"));
			}
			
			_options = new Vector.<Entity>();
			
			addOptions();
			
			setUpFunFact();
		}
		
		private function setUpFunFact():void
		{
			var funFact:Entity = EntityUtils.createSpatialEntity(this,content.funfact,content);
			funFact.add(new Id("funFact"));
			Display(funFact.get(Display)).visible = false;
			
			var pleaseWait:Entity = EntityUtils.createSpatialEntity(this,content.pleasewait,content);
			pleaseWait.add(new Id("pleaseWait"));
			Display(pleaseWait.get(Display)).visible = false;
		}
		
		private function setUpBuyButton():void
		{
			var buy:Entity = EntityUtils.createSpatialEntity(this, content.buy_btn, content);
			TimelineUtils.convertClip(content.buy_btn, this, buy);
			buy.get(Timeline).gotoAndStop("up");
			var interaction:Interaction = InteractionCreator.addToEntity(buy,[InteractionCreator.CLICK, InteractionCreator.OVER, InteractionCreator.OUT], content.buy_btn);
			ToolTipCreator.addToEntity(buy);
			interaction.click.add(buyCoffee);
			interaction.over.add(mouseOver);
			interaction.out.add(buttonUp);
		}
		
		private function buttonUp(button:Entity):void
		{
			button.get(Timeline).gotoAndStop("up");
		}
		
		private function mouseOver(button:Entity):void
		{
			button.get(Timeline).gotoAndStop("over");
		}
		
		private function buyCoffee(entity:Entity):void
		{
			shellApi.triggerEvent(_events.PRESS_BUY_BUTTON);
			
			var content:MovieClip = super.screen.content as MovieClip;
			
			var random:int = int( Math.random() * 10 ) + 1;
			
			content.funfact.gotoAndStop(random);
			
			SceneUtil.lockInput(this);
			
			SceneUtil.addTimedEvent(this, new TimedEvent( 3, 1, Command.create( completePurchase )));
			
			Display(getEntityById("funFact").get(Display)).visible = true;
			Display(getEntityById("pleaseWait").get(Display)).visible = true;
		}
		
		private function completePurchase():void
		{
			SceneUtil.lockInput(this, false);
			if(_right)
			{
				super.shellApi.getItem(_events.COFFEE_CUP_RIGHT,null, true);
				shellApi.setUserField("coffee2",saveString,shellApi.island,true);
			}
			else
			{
				super.shellApi.getItem(_events.COFFEE_CUP_LEFT, null, true);
				shellApi.setUserField("coffee0",saveString,shellApi.island,true);
			}
			super.close();
		}
		
		private function displayCoffee():void
		{
			_coffeeName = "f_"+_size+"_"+_option+"_"+_caffeine;
			_coffee.gotoAndStop(_coffeeName);
			saveString = "["+_option + "," + _size + "," + (2 + _caffeine)+"]";
		}
		
		private function createCaffeineOptions():void
		{
			var c1:Entity = EntityUtils.createSpatialEntity(this, content.c1,content);
			c1.add(new Id("full"));
			TimelineUtils.convertClip(content.c1, this, c1);
			
			var c1Interaction:Interaction = InteractionCreator.addToEntity(c1,[InteractionCreator.CLICK],content.c1);
			ToolTipCreator.addToEntity(c1);
			
			c1Interaction.click.add(chooseCaffeineOption);
			
			var c2:Entity = EntityUtils.createSpatialEntity(this, content.c2,content);
			c2.add(new Id("decaf"));
			TimelineUtils.convertClip(content.c2, this, c2);
			
			var c2Interaction:Interaction = InteractionCreator.addToEntity(c2,[InteractionCreator.CLICK],content.c2);
			ToolTipCreator.addToEntity(c2);
			
			c2Interaction.click.add(chooseCaffeineOption);
		}		
		
		private function chooseCaffeineOption(caffeineOption:Entity):void
		{
			shellApi.triggerEvent(_events.PRESS_OPTION_BUTTON);
			super.getEntityById("decaf").get(Timeline).gotoAndStop(0);
			super.getEntityById("full").get(Timeline).gotoAndStop(0);
			caffeineOption.get(Timeline).gotoAndStop(1);
			if(caffeineOption == super.getEntityById("decaf"))
				_caffeine = 2;
			else
				_caffeine = 0;
			displayCoffee();
		}		
		
		private function addOptions():void
		{
			trace(_right);
			for(var i:int = 0; i < 7; i ++)
			{
				var option:MovieClip = content.getChildByName("m"+i) as MovieClip;
				
				var optionEntity:Entity = EntityUtils.createSpatialEntity(this, option,content);
				
				TimelineUtils.convertClip(option,this,optionEntity);
				
				var random:int = int(Math.random() * _options.length);
				
				if(i == 0 && !_right || i == 3 && _right)
				{
					trace("dont add interaction to this button");
					DisplayUtils.moveToOverUnder(option,content.soldoutlatte,false);
					if(random == i)
						random++;
				}
				else
				{
					var interaction:Interaction = InteractionCreator.addToEntity(optionEntity,[InteractionCreator.CLICK],option);
					
					ToolTipCreator.addToEntity(optionEntity);
					
					interaction.click.add(optionClicked);
				}
				_options.push(optionEntity);
			}
			
			optionClicked(_options[random]);
		}
		
		private function optionClicked(option:Entity):void
		{
			shellApi.triggerEvent(_events.PRESS_OPTION_BUTTON);
			for(var i:int = 0; i < _options.length; i++)
			{
				_options[i].get(Timeline).gotoAndStop(0);
			}
			option.get(Timeline).gotoAndStop(1);
			_option = _options.indexOf(option);
			displayCoffee();
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
		
		private var menuArray:Array = ["Espresso","Macchiato","Con Panna","Latte","Mocha","Americano","Cappuccino", "cup"];
		private var sizeArray:Array = ["Behemoth","Leviathan","Infant"];
		private var caffArray:Array = ["Mega-Caf","Super-Caf","Full-Caf","Half-Caf","Decaf", "empty"];
		
		private var saveString:String = "";
		
		private var content:MovieClip;
		
		private var _right:Boolean;
		
		private var _coffee:MovieClip;
		
		private var _coffeeName:String;
		private var _option:int = 0;
		private var _size:int = 0;
		private var _caffeine:int = 0;
		
		private var _options:Vector.<Entity>;
		
		private var _events:BacklotEvents;
	}
}