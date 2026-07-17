export async function GET(request: Request) {
  return Response.redirect(new URL("/thank-you?mode=demo", request.url));
}
