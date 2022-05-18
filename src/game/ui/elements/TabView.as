package game.ui.elements
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.group.UIView;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.ui.Button;
	import game.components.ui.TabBar;
	import game.creators.ui.ButtonCreator;
	import game.systems.ui.TabBarSystem;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;

	public class TabView extends UIView
	{
		private var _assetPath:String;
		private var _tabBarEntity:Entity;
		private var _tabs:Vector.<TabElement>;
		private var _currentTab:TabElement;
		private var _nextTab:TabElement;
		
		public var tabSelected:Signal;
		public var tabOpened:Signal;
		
		public function TabView(container:DisplayObjectContainer = null)
		{
			super( container );
			super.init( container );
			
			tabSelected = new Signal();
			tabOpened = new Signal();
		}
		
		override public function destroy():void
		{
			// remove all references to this screen's signals
			tabSelected.removeAll();
			tabOpened.removeAll();
			super.destroy()
		}	

		public function create( tabAssetPath:String, tabs:Vector.<TabElement> ):void
		{	
			_assetPath = tabAssetPath;
			_tabs = tabs;
			
			//create tabBar entity
			_tabBarEntity = new Entity();
			_tabBarEntity.add( new TabBar() );
			_tabBarEntity.add( new Children() );
			this.addEntity(_tabBarEntity);
			
			//load tabs
			loadTab( 0 ); 
		}

		public function getTabById( id:String, makeActive:Boolean = false ):TabElement
		{
			for each ( var tab:TabElement in _tabs ) 
			{
				if( tab.id == id )
				{
					if( makeActive )	{ setActive( tab );}
					return tab;
				}
			}
			return null;
		}
		
		public function getTabByIndex( index:uint, makeActive:Boolean = false ):TabElement
		{
			if( _tabs )
			{
				if( makeActive )	{ setActive( _tabs[index] );}
				return _tabs[index];
			}
			return null;
		}
		
		public function setActive( tab:TabElement ):void
		{
			var tabBar:TabBar = _tabBarEntity.get(TabBar);
			
			if( !tabBar.inTransition )
			{
				if( !_currentTab )
				{
					_nextTab = tab;
					_nextTab.open( onTransitionComplete );
				}
				else
				{
					if( _currentTab.id != tab.id )
					{
						tabSelected.dispatch( tab.id );
						_currentTab.close();
						_nextTab = tab;
						_nextTab.open( onTransitionComplete );
						tabBar.inTransition = true;
					}
				}
			}
		}
		
		public function position( x:Number, y:Number ):void
		{	
			super.groupContainer.x = x;
			super.groupContainer.y = y;
		}
		
		//// PRIVATE ////
		
		private function loadTab( index:uint ):void
		{
			super.shellApi.loadFile( super.shellApi.assetPrefix + _assetPath, onTabLoaded, index );
		}
		
		private function onTabLoaded( displayObject:DisplayObjectContainer, index:uint ):void
		{	
			var tab:TabElement = _tabs[index];
			tab.index = index;
			tab.displayObject = MovieClip(displayObject).content;
			tab.init();
			tab.buttonEntity = ButtonCreator.createButtonEntity( tab.displayObject, this, Command.create(tabHandler, tab), super.groupContainer ); // handler ties tabElement to buttonEntity
			Button(tab.buttonEntity.get(Button)).isAnimate = true;	// TODO :: would like to move isAnimate into the creator method
			tab.setOpened(false);
			
			EntityUtils.addParentChild( tab.buttonEntity, _tabBarEntity );
			
			index++;
			if( index != _tabs.length )
			{
				loadTab( index );
			}
			else
			{
				reposition();
				super.addSystem( new TabBarSystem() );
				super.loaded();
			}
		}
		
		private function tabHandler( buttonEntity:Entity, tab:TabElement ):void
		{
			setActive( tab );
		}
		
		private function onTransitionComplete():void
		{
			_currentTab = _nextTab;	
			tabOpened.dispatch( _currentTab.id );
			_nextTab = null;
			
			var tabBar:TabBar = _tabBarEntity.get(TabBar);	// prevents tabBar from TabBarSystem processing
			tabBar.inTransition = false;
			
			reposition();		//finalize positions
		}
		
		private function reposition():void
		{
			for (var i:int = 1; i < _tabs.length; i++) 
			{
				var previousTabDisplay:DisplayObject = _tabs[i - 1].displayObject;
				_tabs[i].displayObject.x = previousTabDisplay.x + previousTabDisplay.width;
			}
		}
		
		
		
		
		
		
		
	
		

		//reposition all tabs when any tab is in transition
	}
}