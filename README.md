# Adhearsion Restful RPC component

Provides a RESTful API for RPC calls over HTTP, allowing control of an Adhearsion application from almost any application.
When enabled, this component will start up a HTTP server within the Adhearsion process and accept POST requests to invoke Ruby methods shared in the methods_for(:rpc) context.

(C) 2011 Mojolingo LLC
