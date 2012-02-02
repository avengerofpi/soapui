/*
 *  soapUI, copyright (C) 2004-2011 eviware.com 
 *
 *  soapUI is free software; you can redistribute it and/or modify it under the 
 *  terms of version 2.1 of the GNU Lesser General Public License as published by 
 *  the Free Software Foundation.
 *
 *  soapUI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
 *  even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
 *  See the GNU Lesser General Public License for more details at gnu.org.
 */

package com.eviware.soapui.impl.wsdl.submit.transports.http.support.methods;

import java.io.IOException;

import javax.net.ssl.SSLSession;

import org.apache.commons.httpclient.util.EncodingUtil;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpDelete;

import com.eviware.soapui.impl.rest.RestRequestInterface;
import com.eviware.soapui.impl.wsdl.submit.transports.http.ExtendedHttpMethod;
import com.eviware.soapui.impl.wsdl.submit.transports.http.HttpMethodSupport;
import com.eviware.soapui.impl.wsdl.submit.transports.http.SSLInfo;
import com.eviware.soapui.impl.wsdl.submit.transports.http.support.metrics.SoapUIMetrics;

/**
 * Extended PostMethod that supports limiting of response size and detailed
 * timestamps
 * 
 * @author Ole.Matzura
 */

public final class ExtendedDeleteMethod extends HttpDelete implements ExtendedHttpMethod
{
	private HttpMethodSupport httpMethodSupport;

	public ExtendedDeleteMethod()
	{
		httpMethodSupport = new HttpMethodSupport();
		getParams().setParameter( ExtendedHttpMethod.HTTP_METRICS, new SoapUIMetrics() );
	}

	public String getDumpFile()
	{
		return httpMethodSupport.getDumpFile();
	}

	public void setDumpFile( String dumpFile )
	{
		httpMethodSupport.setDumpFile( dumpFile );
	}

	public void afterReadResponse( SSLSession session )
	{
		httpMethodSupport.afterReadResponse( session );
	}

	@Override
	public String getResponseCharSet()
	{
		return httpMethodSupport.getResponseCharset();
	}

	public HttpEntity getRequestEntity()
	{
		return null;
	}

	public long getMaxSize()
	{
		return httpMethodSupport.getMaxSize();
	}

	public void setMaxSize( long maxSize )
	{
		httpMethodSupport.setMaxSize( maxSize );
	}

	public long getResponseReadTime()
	{
		return httpMethodSupport.getResponseReadTime();
	}

	public boolean hasResponse()
	{
		return httpMethodSupport.hasResponse();
	}

	public void afterWriteRequest()
	{
		httpMethodSupport.afterWriteRequest();
	}

	public void initStartTime()
	{
		httpMethodSupport.initStartTime();
		getHttpMetrics().getTotalTimer().start();
		//getHttpMetrics().getTimeToFirstByteTimer().start();
	}

	public long getTimeTaken()
	{
		return httpMethodSupport.getTimeTaken();
	}

	public long getStartTime()
	{
		return httpMethodSupport.getStartTime();
	}

	public SSLInfo getSSLInfo()
	{
		return httpMethodSupport.getSSLInfo();
	}

	public String getResponseContentType()
	{
		return httpMethodSupport.getResponseContentType();
	}

	public String getMethod()
	{
		return RestRequestInterface.RequestMethod.DELETE.toString();
	}

	public Throwable getFailureCause()
	{
		return httpMethodSupport.getFailureCause();
	}

	public boolean isFailed()
	{
		return httpMethodSupport.isFailed();
	}

	public void setFailed( Throwable t )
	{
		httpMethodSupport.setFailed( t );
	}

	public byte[] getDecompressedResponseBody() throws IOException
	{
		return httpMethodSupport.getDecompressedResponseBody();
	}

	public void setDecompress( boolean decompress )
	{
		httpMethodSupport.setDecompress( decompress );
	}

	public void setHttpResponse( HttpResponse httpResponse )
	{
		httpMethodSupport.setHttpResponse( httpResponse );
	}

	public HttpResponse getHttpResponse()
	{
		return httpMethodSupport.getHttpResponse();
	}

	public boolean hasHttpResponse()
	{
		return httpMethodSupport.hasHttpResponse();
	}

	public byte[] getResponseBody() throws IOException
	{
		return httpMethodSupport.getResponseBody( getHttpMetrics() );
	}

	public String getResponseBodyAsString() throws IOException
	{
		byte[] rawdata = getResponseBody();
		if( rawdata != null )
		{
			return EncodingUtil.getString( rawdata, getResponseCharSet() );
		}
		else
		{
			return null;
		}
	}

	public SoapUIMetrics getHttpMetrics()
	{
		return ( SoapUIMetrics )getParams().getParameter( ExtendedHttpMethod.HTTP_METRICS );
	}

}
