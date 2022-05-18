package com.poptropica.platformSpecific {

//import com.milkmangames.nativeextensions.GAnalytics;
import com.poptropica.interfaces.IThirdPartyTracker;

import flash.desktop.NativeApplication;
import flash.external.ExternalInterface;
import flash.net.URLVariables;

import de.slashslash.util.Cookie;

import game.util.PlatformUtils;
import game.util.Utils;


public class GoogleAnalyticsTracker implements IThirdPartyTracker {

	public static var GAData:Object = {};

	private static const GA_TRACKING_ID:String = 'UA-350786-20';

	//// CONSTRUCTOR ////

	public function GoogleAnalyticsTracker()
	{
		/*
		if (GAnalytics.isSupported()) {
			GAnalytics.create(GA_TRACKING_ID);
//			GAnalytics.analytics.forceDispatchHits();	// good for debugging, bad for efficiency
			snatchApacheCookie();
		} else {
			trace("GoogleAnalyticsTracker is not supported");
		}
		*/
	}

	//// ACCESSORS ////

	//// PUBLIC METHODS ////

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function snatchApacheCookie():String
	{
		return snatchCookie('Apache');
	}

	private function snatchCookie(cookieName:String):String
	{
		var cookieValue:String;
		if (ExternalInterface.available) {
			GAData.apacheCookie = cookieValue = new Cookie(cookieName).value;
		}
		return cookieValue;
	}

	//// INTERFACE IMPLEMENTATIONS ////

	// IThirdPartyTracker
	
	public function track(vars:URLVariables):void
	{
		//trace("GoogleAnalyticsTracker::track() supported?", GAnalytics.isSupported(), "vars:", vars.toString());
		/*
gender=M&grade=5&event=MissingAsset&scene=Edison&subchoice=Error #2032: Stream Error. URL: app-storage:/sound/effects/ls_dirt_01.mp3&cluster=time&brain=Poptropica2&choice=app-storage:/sound/effects/ls_dirt_01.mp3&platform=mobile
		*/
		/*
		if (! GAnalytics.isSupported()) {
			return;
		}
		if (vars.hasOwnProperty('dimensions')) {
			GAnalytics.analytics.defaultTracker.trackEvent(vars.cluster, vars.event, vars.choice, NaN, vars.dimensions);
		} else {
			GAnalytics.analytics.defaultTracker.trackEvent(vars.cluster, vars.event, vars.choice);
		}
		*/
	}
	
	public function trackPageView(island:String, scene:String):void
	{
		/*
		if (! GAnalytics.isSupported()) {
			return;
		}

		// the last arg to trackScreenView() is a value object which specifies "custom dimensions", in this case we are assigning the app ID to "Custom Dimension 1"
		var dimensions:Object = {};
		ensureCD1(dimensions);
		GAnalytics.analytics.defaultTracker.trackScreenView('/island/' + island + '/' + scene, dimensions);
		*/
	}

	public function trackPageview(vars:URLVariables):void
	{
		/*
		if (! GAnalytics.isSupported()) {
			return;
		}
		var url:String = '/island/' + vars.island + '/' + vars.scene;
		// the last arg to trackScreenView() is a value object which specifies "custom dimensions", in this case we are assigning the app ID to "Custom Dimension 1"
		var dimensions:Object = vars.dimensions ? vars.dimensions : {};
		ensureCD1(dimensions);
		GAnalytics.analytics.defaultTracker.trackScreenView(url, dimensions);
		*/
	}

	private function ensureCD1(o:Object):void
	{
		if (!o.hasOwnProperty('&cd1')) {
			if (PlatformUtils.inBrowser) {
				if (!GAData.hasOwnProperty('apacheCookie')) {
					snatchApacheCookie();
				}
//				o['&cd1'] = GAData.apacheCookie;
			} else {		// we must be on a mobile device
				o['&cd1'] = NativeApplication.nativeApplication.applicationID;
			}
		}
	}

}

}
